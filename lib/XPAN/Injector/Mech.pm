use strict;
use warnings;

package XPAN::Injector::Mech;

use base qw(XPAN::Injector);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => 'mech'
);

use File::Temp ();
use File::Basename ();
use WWW::Mechanize;
sub init_mech { WWW::Mechanize->new }

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
