#!perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use File::Temp qw(tempdir);

BEGIN { 
  if (! system("(svn help && svnadmin help) >/dev/null") ) {
    plan tests => 1;
  } else {
    plan skip_all =>
      'svn(1) and svnadmin(1) are required for testing the svn injector';
  }
}

use XPAN::Archiver::Test;
use Module::Faker::Dist;

my $arch = XPAN::Archiver::Test->new(inject_tests => 0);

my $dist_name = 'FromSVN';

my $dist = Module::Faker::Dist->from_file("t/dist/$dist_name.yaml");

my $repo = tempdir(CLEANUP => 1);
system("svnadmin create $repo >/dev/null") && exit $?;

my $tmp = tempdir(CLEANUP => 1);
my $dist_dir = $dist->make_dist_dir({ dir => $tmp });

system(<<"") && exit $?;
svn import -m test $dist_dir file://$repo/$dist_name >/dev/null

$arch->inject(-SVN => [ "file://$repo/$dist_name" ]);
$arch->contains_dist_ok($dist_name);
