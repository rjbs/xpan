use strict;
use warnings;

package XPAN::Injector;

use Moose::Role;

use Carp ();
use URI;

requires qw(scheme url_to_file);
# requires 'archiver' too, but attributes don't fulfill 'requires'

sub inject {
  my ($self, $url) = @_;
  
  $url = URI->new("$url") unless blessed($url) && $url->isa('URI');
  # a blanket croak is wrong here; some injectors might handle multiple schemes
#  unless ($url->scheme eq $self->scheme) {
#    Carp::croak "$url does not match $self scheme " . $self->scheme;
#  }

  my ($source, $arg)  = $self->prepare($url);

  return $self->archiver->inject_one($source, $arg);
}

sub prepare {
  my ($self, $url) = @_;
  my $filename = $self->url_to_file($url);
  return (
    $filename,
    {
      %{ $self->analyze($filename) },
      file => Path::Class::file($filename)->basename,
    },
  )
}

sub analyze {
  my ($self, $filename) = @_;
  return $self->archiver->analyzer->analyze($filename);
}

1;
