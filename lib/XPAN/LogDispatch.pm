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

1;
