use strict;
use warnings;

package XPAN::Analyzer;

use Moose;
# with 'XPAN::Helper';

use CPAN::DistnameInfo;
use CPAN::Version;
use File::pushd ();
use Path::Class ();
use ExtUtils::Manifest ();
use Cwd ();
require ExtUtils::MM;

sub parse_meta {
  my ($self, $yaml) = @_;
  require YAML::Syck;
  my $meta = YAML::Syck::Load($yaml);
  
  my %dist;
  for (qw(name version abstract)) {
    $dist{$_} = $meta->{$_} if exists $meta->{$_};
  }
  for my $module (keys %{ $meta->{requires} || {} }) {
    push @{ $dist{dependencies} ||= [] }, {
      name => $module,
      version => $meta->{requires}{$module} || 0,
      source => 'META.yml',
    };
  }
  return %dist;
}

sub parse_packages_from_pm {
  my ($self, $file) = @_;
  my %pkg;
  open my $fh, '<', $file or return undef;

  # stealing from PAUSE indexer.
  local $/ = "\n";
  local $_;
  my $inpod = 0;
      PLINE: while (<$fh>) {
            chomp;
            my($pline) = $_;
            $inpod = $pline =~ /^=(?!cut)/ ? 1 :
                $pline =~ /^=cut/ ? 0 : $inpod;
            next if $inpod;
            next if substr($pline,0,4) eq "=cut";

            $pline =~ s/\#.*//;
            next if $pline =~ /^\s*$/;
            last PLINE if $pline =~ /\b__(END|DATA)__\b/;

            my $pkg;

            if (
                $pline =~ m{
                         (.*)
                         \bpackage\s+
                         ([\w\:\']+)
                         \s*
                         ( $ | [\}\;] )
                        }x) {
                $pkg = $2;

            }

            if ($pkg) {
                # Found something

                # from package
                $pkg =~ s/\'/::/;
                next PLINE unless $pkg =~ /^[A-Za-z]/;
                next PLINE unless $pkg =~ /\w$/;
                next PLINE if $pkg eq "main";
        #next PLINE if length($pkg) > 64; #64 database
                #restriction
                $pkg{$pkg}{file} = $file;
        my $version = MM->parse_version($file);
        $pkg{$pkg}{version} = $version if defined $version;
            }
        }

  
  close $fh;
  return \%pkg;
}

sub _ignore_pmfile {
  my ($self, $pmfile) = @_;
  return 1 if $pmfile =~ m{^(inc|t)/};
}

sub _find_dist_dir {
  my ($self) = @_;

  my $cwd = Path::Class::dir(Cwd::cwd());

  my @children = $cwd->children;
  if (@children == 1 and $children[0]->is_dir) {
    return $children[0];
  }

  my %files = %{ ExtUtils::Manifest::manifind() };

  my (@dist_files) = grep {
    /\bMANIFEST(\.SKIP)?\b/ ||
    /\bMakefile.PL\b/ ||
    /\bBuild.PL\b/
  } keys %files;

  if (@dist_files) {
    return Path::Class::file($dist_files[0])->dir;
  }

  my @pm_files = grep { /\.pm$/i } keys %files;

  if (@pm_files) {
    my $file = Path::Class::file($pm_files[0]);
    while ($file->dir) {
      $file = $file->dir;
    }
    return $file;
  }

  die "can't figure out root directory";
}

sub scan_for_provides {
  my ($self, $tar) = @_;
  if (not ref $tar) {
    my $t = Archive::Tar->new;
    $t->read($tar);
    $tar = $t;
  }

  my %pkg;
  {
    my $temp_dir = File::pushd::tempd;

    $tar->extract;

    {
      #warn "using $dist_file to determine root\n";
      my $dist_dir = File::pushd::pushd( $self->_find_dist_dir );
      #warn "$dist_file is in $dist_dir\n";
      my @pmfiles = grep { /\.pm$/i } keys %{ ExtUtils::Manifest::manifind() };

      foreach my $pmfile (grep { ! $self->_ignore_pmfile($_) } @pmfiles) {
        #warn "parsing: $pmfile\n";
        
        my $hash = $self->parse_packages_from_pm($pmfile);
        next if not defined $hash;
        foreach (keys %$hash) {
          my $name = (split /::/)[-1];
          $pkg{$_} = $hash->{$_}
            if not defined $pkg{$_}{version} or $pkg{$_}{version} eq 'undef'
            or (defined $hash->{$_}{version} and 
              (
                $pkg{$_}{version} < $hash->{$_}{version} or
                # prefer simile
                ($pkg{$_}{version} == $hash->{$_}{version} and
                  $pmfile =~ /\b\Q$name.\Epm$/
                )
              )
            );
        }
      }
    }
  }

  return unless %pkg;

  return (
    provides => [
      map { {
        name    => $_,
        version => (
          $pkg{$_}{version} eq 'undef'
            ? undef : $pkg{$_}{version}
        ),
        file    => $pkg{$_}{file},
      } } keys %pkg
    ],
  );
}

sub analyze {
  my ($self, $filename) = @_;
  my $d = CPAN::DistnameInfo->new($filename);

  require Archive::Tar;
  require Archive::Zip;
  my $type = $filename =~ /\.zip$/ ? 'Zip' : 'Tar';
  my $tar = "XPAN::Analyzer::Archive::$type"->new(
    archive => "Archive::$type"->new,
  );
  $tar->read($filename);

  my $base = $d->distvname;

  my %dist = (
    name => $d->dist,
    version => $d->version,
  );
  
  {
    local $Archive::Tar::WARN = 0;
    if ($tar->contains("$base/META.yml")) {
      my %meta = eval { 
        $self->parse_meta($tar->content("$base/META.yml"));
      };
      if (my $e = $@) {
        $self->log->warning("could not parse $base/META.yml: $e");
      } elsif (not %meta) {
        $self->log->warning("$base/META.yaml returned undef");
      }

      # people pretty frequently forget to bump META.yml (I guess their build
      # tools don't handle it automatically?)
      if ($dist{version} and $meta{version} and
        CPAN::Version->vlt($meta{version}, $dist{version}) and
        my $cfg = 1 # $self->config->get('meta_yml_ignore_lower_version')
      ) {
        if ($cfg eq 'warn') {
          $self->log->warning([
            "version %s from META.yml is lower than dist filename version %s,"
            . " ignoring it",
            $meta{version}, $dist{version},
          ]);
        }
        delete $meta{version};
      }

      %dist = (%dist, %meta);
      #use Data::Dumper; warn Dumper(\%meta, \%dist);
    }
  }

  %dist = (%dist, $self->scan_for_provides($tar));

  #use Data::Dumper; warn Dumper(\%dist);
  return \%dist;
}

{
  package XPAN::Analyzer::Archive;
  use Moose;
  has archive => (is => 'ro', required => 1, handles => [qw(read)]);
}

{
  package XPAN::Analyzer::Archive::Zip;
  use Moose;
  extends 'XPAN::Analyzer::Archive';

  sub content { shift->archive->contents(shift) }
  sub extract { shift->archive->extractTree }
  sub contains { shift->archive->memberNamed(shift) ? 1 : 0}
}

{
  package XPAN::Analyzer::Archive::Tar;
  use Moose;
  extends 'XPAN::Analyzer::Archive';

  sub content { shift->archive->get_content(shift) }
  sub extract { shift->archive->extract }
  sub contains { shift->archive->contains_file(shift) }
}

1;
