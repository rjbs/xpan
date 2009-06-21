use strict;
use warnings;

package XPAN::Injector;

use Moose::Role;
with 'XPAN::ResultSource';
use Carp ();
use URI;

requires qw(scheme url_to_file);
# requires 'archiver' too, but attributes don't fulfill 'requires'

sub name {
  my ($self) = @_;
  my $name = blessed($self) || $self;
  return +(split /::/, $name)[-1];
}

sub inject {
  my ($self, $url) = @_;
  blessed($url) or $url = URI->new($url);
  my $dist = eval {
    $url = $self->normalize($url);
    my ($source, $arg)  = $self->prepare($url);
    $self->archiver->inject_one($source, $arg);
  };
  if (my $e = XPAN::Result->caught) {
    return $e;
  } elsif ($@) { die $@ }
  return $self->make_result('Success', dist => $dist);
}

sub prepare {
  my ($self, $url) = @_;
  my $filename = $self->url_to_file($url);
  my %p = %{ $self->analyze($filename) };
  if ($p{name} and $p{version}) {
    my $dist = $self->archiver->dist->new(
      name    => $p{name},
      version => $p{version}
    )->load(speculative => 1);
    if ($dist) {
      $self->throw_result('Success::Already', dist => $dist, dist => $dist);
    }
  }
  return (
    $filename,
    {
      %p,
      file      => Path::Class::file($filename)->basename,
      origin    => $url,
      authority => $self->url_to_authority($url),
    },
  )
}

sub normalize { $_[1] }

sub url_to_authority {
  my ($self, $url) = @_;
  return $self->context->user->authority;
}

sub analyze {
  my ($self, $filename) = @_;
  return $self->archiver->analyzer->analyze($filename);
}

1;
