use strict;
use warnings;

package XPAN::Injector::Mech;

use Moose;
with qw(XPAN::Helper XPAN::Injector);

sub scheme { 'http' }

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

sub url_to_file {
  my ($self, $url) = @_;
  blessed($url) or $url = URI->new("$url");

  my $link = $self->scrape($url);

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  $self->mech->get($link);
  my $filename = "$dir/" . File::Basename::basename($link);
  $self->mech->save_content($filename);
  return $filename;
}

1;
