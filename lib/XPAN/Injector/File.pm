use strict;
use warnings;

package XPAN::Injector::File;

use base qw(XPAN::Injector);

sub scheme { 'file' }

sub arg_to_filename { $_[1] }

1;
