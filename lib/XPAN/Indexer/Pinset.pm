use strict;
use warnings;

package XPAN::Indexer::Pinset;

use base qw(XPAN::Indexer::Latest);
use Rose::Object::MakeMethods::Generic (
  'scalar --get_set_init' => 'pinset',
);

use Carp;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{pinset} &&= $self->archiver->pinset->smart_find($self->{pinset});
  return $self;
}

sub init_pinset { Carp::croak "'pinset' is required" }

sub name { shift->pinset->name }

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
