#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XPAN' );
}

diag( "Testing XPAN $XPAN::VERSION, Perl $], $^X" );
