use strict;
use warnings;

package XPAN::Context;

use Moose;

use XPAN::LogDispatch;
use XPAN::User;
use Carp ();

has log => (
  is => 'ro',
  isa => 'Log::Dispatch',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my $d = XPAN::LogDispatch->new;
    $d->add($self->loggers);
    return $d;
  },
  handles => [
      #log log_and_die log_and_croak
    qw(
      debug info notice warning error critical alert emergency
      err crit emerg
    )
  ],
);

has loggers => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy => 1,
  auto_deref => 1,
  default => sub {
    return [
      [ 'screen' ],    
    ];
  },
);

has user => (
  is => 'ro',
  isa => 'XPAN::User',
  lazy => 1,
  default => sub { XPAN::User->new },
);

1;
