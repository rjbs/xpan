use strict;
use warnings;

package XPAN::Helper;

use Moose::Role;

has archiver => (
  is       => 'ro',
  required => 1,
  isa      => 'XPAN::Archiver',
  weak_ref => 1,
  handles => [qw(context log)],
);

sub config {
  my ($self) = @_;
  my $key = blessed($self) || $self;
  return $self->archiver->config->get($key);
}

1;
