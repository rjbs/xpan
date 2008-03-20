use strict;
use warnings;
use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;
use Module::Faker::Dist;

my $archiver = XPAN::Archiver::Test->new(inject_tests => 0);

$archiver->inject(-File => [
  map { 
    Module::Faker::Dist
      ->from_file("t/dist/Scan-Test-$_.yaml")
      ->make_archive
  } qw(0.09 0.10)
]);

my $iter = $archiver->dists_by_name_iterator;

my ($name, $dists) = $iter->();
#use Data::Dump::Streamer;
#diag Dump($name, $dists);

my $chosen = $archiver->indexer(-Latest)->choose_distribution_version(@$dists);

is($chosen->name, $name, "right dist name");
is($chosen->version, '0.10', "right dist version");
