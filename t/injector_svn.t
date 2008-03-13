#!perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use File::Temp qw(tempdir);
use File::pushd;

BEGIN { 
  if (! system("(svn help && svnadmin help) >/dev/null") ) {
    plan 'no_plan';
  } else {
    plan skip_all =>
      'svn(1) and svnadmin(1) are required for testing the svn injector';
  }
}

use XPAN::Archiver::Test;
use TestDist::Loader;

my $loader = TestDist::Loader->new;
my $arch = XPAN::Archiver::Test->new;

my $dist_name = 'FromSVN';

my $dist = $loader->get_dist($dist_name);

my $repo = tempdir(CLEANUP => 1);
system("svnadmin create $repo >/dev/null") && exit $?;

{
  my $tmp = tempd;
  $dist->tar->extract;
  system(<<"") && exit $?;
svn import -m test $tmp/$dist_name file://$repo/$dist_name >/dev/null

}

$arch->inject(-SVN => [ "file://$repo/$dist_name" ]);
$arch->contains_dist_ok($dist_name);
