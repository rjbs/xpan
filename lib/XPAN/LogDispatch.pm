use strict;
use warnings;

package XPAN::LogDispatch;

use Moose;
BEGIN { extends 'Log::Dispatch' }

BEGIN {
  for my $l (keys %Log::Dispatch::LEVELS) {
    no strict 'refs';
    my $super = "SUPER::$l";
    *$l = sub {
      my $self = shift;
      if (@_ == 1 and ref $_[0] eq 'ARRAY') {
        my ($fmt, @rest) = @{+shift};
        $self->$super(sprintf($fmt, @rest));
      } else {
        $self->$super(@_);
      }
    };
  }
}

sub _loggers {
  my $self = shift;
  my @obj;
  for (@_) {
    if (ref $_ eq 'ARRAY') {
      push @obj, $self->build_logger(@$_);
    } else {
      push @obj, $_;
    }
  }
  return @obj;
}

sub add {
  my $self = shift;
  $self->SUPER::add($self->_loggers(@_));
}

sub replace {
  my $self = shift;
  my @obj = $self->_loggers(@_);
  $self->remove($_->name) for @obj;
  $self->SUPER::add(@obj);
}

use Log::Dispatch::Screen;

my %logger_config = (
  screen => {
    class => 'Log::Dispatch::Screen',
    min_level => 'debug',
    callbacks => sub { my %p = @_; "$p{message}\n" },
  },
);

sub build_logger {
  my ($self, $l_name, $extra) = @_;
  $extra ||= {};
  my $config = $logger_config{$l_name}
    or Carp::croak "no such logger: $l_name";
  return $config->{class}->new(
    name => $l_name,
    min_level => $config->{min_level},
    callbacks => $config->{callbacks},
    %$extra,
  );
}

1;
