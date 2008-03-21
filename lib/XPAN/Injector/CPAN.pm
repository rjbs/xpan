use strict;
use warnings;

package XPAN::Injector::CPAN;

use base qw(XPAN::Injector::Mech);

sub scheme { 'cpan' }

sub scrape {
  my ($self, $url) = @_;
  (my $name = $url->path) =~ s{^/}{};
  $self->mech->get("http://search.cpan.org/dist/$name");
  my $match = $name =~ /-\d+\.\d+/ ? $name : qr/$name-(\d+\.\d+(_\d+)?)/;
  my ($link) = $self->mech->find_link(
    url_regex => qr{/$match\.tar\.gz$},
  );
  # do anything with author ID, now that we have it?
  return $link->url_abs;
}

1;
