use strict;
use warnings;

use Test::More 'no_plan';
use XPAN::Archiver;
use File::Temp;

my $dir = File::Temp::tempdir(CLEANUP => 1);

my $archiver = XPAN::Archiver->new(
  path => $dir,
);

$archiver->inject(-File => [ 't/dist/Scan-Test-0.10.tar.gz' ]);

my $dists = $archiver->dist->manager->get_objects;
  
is(@$dists, 1, "one dist found");

my $dist = $dists->[0];

isa_ok($dist, $archiver->dist);
is($dist->name, "Scan-Test");
is($dist->version, '0.10');
is($dist->file, 'Scan-Test-0.10.tar.gz');

my @modules = $dist->modules;
is(@modules, 2, "two modules found");
is($modules[0]->name, "Scan::Test");
is($modules[1]->name, "Scan::Test::Inner");

ok(
  -e $archiver->path->subdir('dist')->file('Scan-Test-0.10.tar.gz'),
  "dist file copied to archive subdir",
);
