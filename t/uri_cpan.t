use strict;
use warnings;
use Test::More 'no_plan';
use URI;

package URI::mytest;

use base qw(URI::cpan);

sub _path_parts { qw(a b[2] c[*]) }

sub a { shift->_path_part(a => @_) }
sub b { shift->_path_part(b => @_) }
sub c { shift->_path_part(c => @_) }

package URI::mytest::test;

use base qw(URI::mytest);

package main;

my $url = URI->new("mytest://test/a/b1/b2/c1/c2/c3");

is($url->a, 'a');
is($url->b, '/b1/b2');
is($url->c, '/c1/c2/c3');
eval { $url->_splice_part('d') };
like $@, qr/invalid path part: 'd'/;

$url = URI->new("mytest://test/a/b1");
is($url->c, '');
is($url->b, '/b1');
is($url->c('/c1/c2'), '/c1/c2');
is($url->a('A'), 'A');
is($url, "mytest://test/A/b1/c1/c2");
