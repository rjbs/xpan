use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;
use Module::Faker::Dist;

my $archiver = XPAN::Archiver::Test->new(inject_tests => 0);

$archiver->auto_inject(
  'file://' . 
  Module::Faker::Dist
    ->from_file('t/dist/Scan-Test-0.10.yaml')
    ->make_archive,
);

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
