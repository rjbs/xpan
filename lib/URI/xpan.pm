use strict;
use warnings;

use URI::cpan;

package URI::xpan;
our @ISA = qw(URI::cpan);

package URI::xpan::dist;
our @ISA = qw(URI::cpan::dist);

package URI::xpan::pin;
our @ISA = qw(URI::xpan::dist);

package URI::xpan::package;
our @ISA = qw(URI::cpan::package);

package URI::xpan::id;
our @ISA = qw(URI::cpan::id);

sub id { shift->cpanid(@_) }

1;
