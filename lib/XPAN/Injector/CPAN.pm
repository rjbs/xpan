use strict;
use warnings;

package XPAN::Injector::CPAN;

use base qw(XPAN::Injector);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => 'mech'
);

use File::Temp ();
use File::Basename ();
use WWW::Mechanize;
sub init_mech { WWW::Mechanize->new }

sub scheme { 'cpan' }

sub scrape {
  my ($self, $name) = @_;
  $self->mech->get("http://search.cpan.org/dist/$name");
  my $match = $name =~ /-\d+\.\d+/ ? $name : qr/$name-(\d+\.\d+(_\d+)?)/;
  my ($link) = $self->mech->find_link(
    url_regex => qr{/$match\.tar\.gz$},
  );
  # do anything with author ID, now that we have it?

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  $self->mech->get($link->url_abs);
  my $filename = "$dir/" . File::Basename::basename($link->url);
  $self->mech->save_content($filename);
  return $filename;
}

sub arg_to_filename { shift->scrape(shift) }

1;
