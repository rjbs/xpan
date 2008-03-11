use strict;
use warnings;

package TestDist;

use Archive::Tar;
#use Archive::Tar::Constant ();
use YAML::Syck;
use Moose;
use CPAN::DistnameInfo;
use File::Basename;

has filename => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has prefix => (
  is => 'ro',
  isa => 'Str',
  default => '',
);

has include_prefix => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
);

has files => (
  is => 'rw',
  isa => 'HashRef[Str]',
);

sub tar {
  my ($self) = @_;
  my $tar = Archive::Tar->new;

  for my $file (keys %{ $self->files }) {
    my $tarfile = $tar->add_data(
      $file, $self->files->{$file},
    ) or die "Can't add $file: " . $tar->error;
    # despite the docs, this doesn't seem to work in the opthashref
    $tarfile->prefix($self->prefix);
  }
  return $tar;
}

sub write {
  my ($self, $dir) = @_;
  
  $self->tar->write(
    "$dir/" . $self->filename,
    1, # compressed
  );
}

sub load {
  my ($class, $file) = @_;
  my $data = YAML::Syck::LoadFile($file);
  (my $name = File::Basename::basename($file)) =~ s/\.dist$/.tar.gz/;
  my $info = CPAN::DistnameInfo->new($name);
  $data->{filename} ||= $name;
  $data->{prefix}   ||= $info->distvname;
  return $class->new($data);
}

1;
