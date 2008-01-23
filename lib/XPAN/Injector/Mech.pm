use strict;
use warnings;

package XPAN::Injector::Mech;

use Moose;
extends 'XPAN::Injector';

has mech => (
  is => 'ro',
  lazy => 1,
  isa => 'WWW::Mechanize',
  default => sub { shift->mech_class->new },
);

has mech_class => (
  is => 'ro',
  lazy => 1,
  default => sub { 'WWW::Mechanize' },
);

use File::Temp ();
use File::Basename ();
use WWW::Mechanize;

sub arg_to_filename {
  my ($self, $arg) = @_;

  my $link = $self->scrape($arg);

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  $self->mech->get($link);
  my $filename = "$dir/" . File::Basename::basename($link);
  $self->mech->save_content($filename);
  return $filename;
}

1;
