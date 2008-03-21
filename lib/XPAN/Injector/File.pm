use strict;
use warnings;

package XPAN::Injector::File;

use Moose;

with qw(XPAN::Object::HasArchiver XPAN::Injector);

sub scheme { 'file' }

sub url_to_file { pop->path }

1;
