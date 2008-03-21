use strict;
use warnings;

package XPAN::Injector;

use Moose::Role;

use Carp ();
use URI;

requires qw(scheme url_to_file);
# requires 'archiver' too, but attributes don't fulfill 'requires'

sub inject {
  my ($self, $url, $opt) = @_;
  
  blessed($url) or $url = URI->new($url);
  # a blanket croak is wrong here; some injectors might handle multiple schemes
#  unless ($url->scheme eq $self->scheme) {
#    Carp::croak "$url does not match $self scheme " . $self->scheme;
#  }

  my ($source, $arg)  = $self->prepare($url, $opt);

  return $self->archiver->inject_one($source, $arg);
}

sub prepare {
  my ($self, $url, $opt) = @_;
  $opt ||= {};
  my $filename = $self->url_to_file($url);
  return (
    $filename,
    {
      %{ $self->analyze($filename) },
      file      => Path::Class::file($filename)->basename,
      origin    => $url,
      authority => $self->url_to_authority($url),
      %{ $opt->{extra} || {} },
    },
  )
}

sub url_to_authority {
  my ($self, $url) = @_;
  require Sys::Hostname::Long;
  my $user = getpwuid($<);
  return sprintf 'local:%s@%s', $user, Sys::Hostname::Long::hostname_long();
}

sub analyze {
  my ($self, $filename) = @_;
  return $self->archiver->analyzer->analyze($filename);
}

1;
