use strict;
use warnings;

package XPAN::Injector::BackPAN;

use base qw(XPAN::Injector::Mech);
use Parse::BACKPAN::Packages;
use CPAN::DistnameInfo;

my $p;

sub scheme { 'backpan' }

sub scrape {
  my ($self, $name) = @_;

  $p ||= Parse::BACKPAN::Packages->new;

  # fake it!
  my $info = CPAN::DistnameInfo->new("$name.tar.gz");

  my (@d) = grep {
    $_->dist eq $info->dist and (
      defined $info->version and (
        $_->version eq $info->version
      )
    )
  } $p->distributions($info->dist);

  unless (@d) {
    die "no distributions found matching '$name'";
  }

  my $dist = $self->archiver->dist->new(
    name => $d[-1]->dist,
    version => $d[-1]->version,
  )->load(speculative => 1);
  if ($dist) {
    die "'$name' is already a distribution";
  }

  return "http://backpan.cpan.org/" . $d[-1]->prefix;
}

1;
