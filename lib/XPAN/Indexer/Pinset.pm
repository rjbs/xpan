use strict;
use warnings;

package XPAN::Indexer::Pinset;

use Moose;
extends 'XPAN::Indexer::Latest';

use Moose::Util::TypeConstraints;

subtype 'Pinset'
  => as 'Object'
  => where { $_->isa('XPAN::Pinset') };

coerce 'Pinset'
  => from 'Int'
  => via { XPAN::Pinset->new(id => $_)->load }
  => from 'Str'
  => via { XPAN::Pinset->new(name => $_)->load };

has pinset => (
  is => 'ro',
  isa => 'Pinset',
  required => 1,
  coerce => 1,
  handles => [qw(name)],
);

use Carp;

sub choose_distribution_version {
  my $self = shift;
  my $name = shift;
  my @dists = @_;

  my ($pin) = $self->pinset->find_pins({ name => $name });

  unless ($pin) {
    return $self->SUPER::choose_distribution_version($name, @dists);
  }
  my ($match) = grep { $_->version eq $pin->version } @dists;

  unless ($match) {
    Carp::confess "no pin found matching " . $pin->as_string;
  }

  return $match;
}

1;
