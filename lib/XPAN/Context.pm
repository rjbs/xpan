use strict;
use warnings;

package XPAN::Context;

use Moose;

#with 'XPAN::Helper';

use Log::Dispatch;
use Log::Dispatch::Screen;
use XPAN::User;

has log => (
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
      Log::Dispatch::Screen->new(
        name => 'screen', min_level => 'debug',
        callbacks => sub { my %p = @_; "$p{message}\n" },
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
