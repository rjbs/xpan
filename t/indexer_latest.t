use strict;
use warnings;
use Test::More 'no_plan';
use XPAN::Archiver;
use File::Temp;

my $dir = File::Temp::tempdir(CLEANUP => 1);

my $archiver = XPAN::Archiver->new(
  path => $dir,
);

$archiver->inject(-File => [
  't/dist/Scan-Test-0.10.tar.gz',
  't/dist/Scan-Test-0.09.tar.gz',
]);

my $iter = $archiver->dists_by_name_iterator;

my ($name, $dists) = $iter->();
#use Data::Dump::Streamer;
#diag Dump($name, $dists);

my $chosen = $archiver->indexer(-Latest)->choose_distribution_version(@$dists);

is($chosen->name, $name, "right dist name");
is($chosen->version, '0.10', "right dist version");
