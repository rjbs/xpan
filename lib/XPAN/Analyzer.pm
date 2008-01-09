use strict;
use warnings;

package XPAN::Analyzer;

use base qw(Rose::Object);
use CPAN::DistnameInfo;

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
      module_name => $module,
      module_version => $meta->{requires}{$module},
      source => 'META.yml',
    };
  }
  return %dist;
}

sub analyze {
  my ($self, $filename) = @_;
  my $d = CPAN::DistnameInfo->new($filename);

  require Archive::Tar;
  my $tar = Archive::Tar->new;
  $tar->read($filename);

  my $base = $d->distvname;

  my %dist = (
    name => $d->dist,
    version => $d->version,
  );
  local $Archive::Tar::WARN = 0;
  if ($tar->contains_file("$base/META.yml")) {
    %dist = (%dist, $self->parse_meta(
      $tar->get_content("$base/META.yml")
    ));
  }

  return \%dist;
}



1;
