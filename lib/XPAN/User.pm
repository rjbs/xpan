use strict;
use warnings;

package XPAN::User;

use Moose;

use Sys::Hostname::Long;

has authority => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub { sprintf '%s@%s', scalar(getpwuid($<)), hostname_long },
);

1;
