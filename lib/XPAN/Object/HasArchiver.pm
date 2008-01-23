use strict;
use warnings;

package XPAN::Object::HasArchiver;

use Moose;
extends 'XPAN::Object';

has archiver => (
  is       => 'ro',
  required => 1,
  isa      => 'XPAN::Archiver',
  weak_ref => 1,
);

1;
