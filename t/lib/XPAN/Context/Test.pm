use strict;
use warnings;

package XPAN::Context::Test;

use Moose;
BEGIN { extends 'XPAN::Context' }

has '+loggers' => (
  default => sub {
    return [
      [ screen => { min_level => 'emerg' } ],
    ];
  },
); 

1;
