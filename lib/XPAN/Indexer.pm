use strict;
use warnings;

package XPAN::Indexer;

use Moose;
with qw(XPAN::Helper);

has dists => (
  is => 'ro',
  isa => 'ArrayRef[XPAN::Dist]',
  auto_deref => 1,
  default => sub { [] },
);

has faker => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return CPAN::Faker->new({
      source  => '/dev/null',
      dest    => $self->path->stringify,
    });
  },
);

use Carp ();
use CPAN::Checksums ();
use HTTP::Date ();
use IO::Zlib;
use CPAN::Faker;

my %FILE = (
  '02packages' => '02packages.details.txt',
);

sub choose_distribution_version { Carp::croak "unimplemented" }

sub name { Carp::croak "unimplemented" }

sub path {
  my $self = shift;
  return $self->archiver->path->subdir('index')->subdir($self->name);
}

sub build {
  my ($self) = @_;

  $self->clear_index;
  $self->build_index_files;
  $self->add_all_distributions;
}

sub clear_index {
  my ($self) = @_;
  $self->path->rmtree;
}

sub build_index_files {
  my ($self) = @_;
  $self->faker->write_author_index;
  $self->faker->write_modlist_index;
}

sub each_distribution {
  my ($self, $code) = @_;
  my $iter = $self->archiver->dists_by_name_iterator;
  while (my ($name, $dists) = $iter->()) {
    # let Indexer::Pinset manage these
    next if $name =~ /^XPAN-Task-Pinset-/;
    my $dist = $self->choose_distribution_version($name => @$dists)
      or next;
    local $_ = $dist;
    $code->();
  }
  for my $dist ($self->extra_distributions) {
    local $_ = $dist;
    $code->();
  }
}

sub all_distributions {
  my ($self) = @_;
  my @dists;
  $self->each_distribution(sub { push @dists, $_ });
  return @dists;
}

sub extra_distributions { () }

sub add_all_distributions {
  my ($self) = @_;
  my %cpanid;
  $self->each_distribution(sub {
    $self->add_distribution($_);
    $cpanid{$_->cpanid}++;
  });
  $self->write_02packages;
  CPAN::Checksums::updatedir($self->author_dir($_)) for keys %cpanid;
}

sub add_distribution {
  my ($self, $dist) = @_;
  $self->add_to_dists($dist);
  $self->add_distribution_link($dist);
}

sub index_fh {
  my ($self, $filename) = @_;
  $filename = $FILE{$filename};
  $self->{index_fh}{$filename} ||= do {
    $self->path->subdir('modules')->mkpath;
    $self->path->subdir('modules')->file($filename)->openw;
  };
}

sub gzip_index_file {
  my ($self, $filename) = @_;
  $filename = $FILE{$filename};
  my $file = $self->path->subdir('modules')->file($filename);
  my $fh = $file->openr;
  my $gz = IO::Zlib->new("$file.gz", "w");
  while (<$fh>) { print { $gz } $_ }
}

sub add_to_dists {
  my ($self, $dist) = @_;
  push @{ $self->dists }, $dist;
}

sub write_02packages {
  my $self = shift;
  my $count = 0;
  for my $d ($self->dists) { for my $m ($d->modules) { $count++ } }
  my $fh = $self->index_fh('02packages');
  print $fh sprintf <<END,
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   LOCAL
Line-Count:   %s
Last-Updated: %s

END
    $count,
    HTTP::Date::time2str;

  for my $dist ($self->dists) {
    for my $module ($dist->modules) {
      my $tail = (split /::/, $module->name)[-1];
      next if $module->is_inner_package
        # wtf? copying PAUSE
        and $module->file !~ /VERSION/i
        # PAUSE would leave out the \b, but I want to make sure that
        # B/BUtils.pm, containing B::Utils, does not get indexed
        and $module->file !~ /\b$tail\.pm/
      ;

      print $fh sprintf "%-30s %8s  %s\n",
        $module->name,
        (defined $module->version ? $module->version : 'undef'),
          $self->author_dir($dist->cpanid)->relative(
            $self->path->subdir('authors')->subdir('id')
          )->file($dist->file),
      ;
    }
  }
  close $fh;
  $self->gzip_index_file('02packages');
}

sub author_dir {
  my ($self, $id) = @_;
  my $path = $self->path->subdir('authors')->subdir('id');
  $path = $path->subdir(substr($id, 0, 1));
  $path = $path->subdir(substr($id, 0, 2));
  return $path->subdir($id);
}

sub add_distribution_link {
  my ($self, $dist) = @_;

  my $author_dir = $self->author_dir($dist->cpanid);
  $author_dir->mkpath;
  my $file = $author_dir->file($dist->file);

  my $target =
    $self->archiver->path->subdir('dist')->file($dist->path)->absolute;
  #warn "linking $file -> $target\n";
  symlink(
    $target,
    $file,
  ) or die "Can't symlink $file -> $target: $!";
}

1;
