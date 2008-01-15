use strict;
use warnings;

package XPAN::Object::HasArchiver;

use base qw(XPAN::Object);

use Rose::Object::MakeMethods::WeakRef (
  scalar => [
    archiver => { interface => 'get_set_init' },
  ],
);

use Carp;
sub init_archiver { Carp::croak "'archiver' is required" }

1;
