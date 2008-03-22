use strict;
use warnings;

package XPAN::Helper;

use Moose::Role;

has archiver => (
  is       => 'ro',
  required => 1,
  isa      => 'XPAN::Archiver',
  weak_ref => 1,
);

1;
