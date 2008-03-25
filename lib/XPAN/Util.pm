use strict;
use warnings;

package XPAN::Util;

use Sub::Exporter -setup => {
  exports => [qw(iter)],
};

sub iter (&) { bless $_[0] => 'XPAN::Util::Iterator' }

package XPAN::Util::Iterator;

sub next { shift->() }

1;
