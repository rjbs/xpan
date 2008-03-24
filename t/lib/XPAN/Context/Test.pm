use strict;
use warnings;

package XPAN::Context::Test;

use Moose;
BEGIN { extends 'XPAN::Context' }

has '+user' => (
  default => sub { XPAN::User->new }
);

1;
