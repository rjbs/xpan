use strict;
use warnings;

package XPAN::Indexer::Latest;

use base qw(XPAN::Indexer);
use Sort::Versions;

sub name { 'latest' }

sub choose_distribution_version {
  my $self = shift;

  my $chosen;
  for my $possible (@_) {
    if (! $chosen or versioncmp($chosen->version, $possible->version) == 1) {
      $chosen = $possible;
    }
  }
  return $chosen;
}

1;
