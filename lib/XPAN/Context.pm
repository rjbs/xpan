use strict;
use warnings;

package XPAN::Context;

use Moose;

#with 'XPAN::Helper';

use Log::Dispatch;
use Log::Dispatch::Screen;
use XPAN::User;

has logger => (
  is => 'ro',
  isa => 'Log::Dispatch',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my $d = Log::Dispatch->new;
    $d->add($self->loggers);
    return $d;
  },
  handles => [
    qw(
      log log_and_die log_and_croak
      debug info notice warning error critical alert emergency
      err crit emerg
    )
  ],
);

has log_objects => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy => 1,
  auto_deref => 1,
  default => sub {
    return [
      Log::Dispatch::Screen->new(
        name => 'screen', min_level => 'debug',
        callbacks => sub { pop->{message} . "\n" },
      )
    ];
  },
);

has user => (
  is => 'ro',
  isa => 'XPAN::User',
  required => 1,
);

1;
