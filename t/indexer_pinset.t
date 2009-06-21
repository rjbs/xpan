use strict;
use warnings;
use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;

my $archiver = XPAN::Archiver::Test->new;

my $ps = $archiver->pinset->new(
  name => 'test',
)->save;

$ps->add_pins(
  {
    name => 'Scan-Test',
    version => '0.10',
  },
);
$ps->save;

my $ix = $archiver->indexer(-Pinset => pinset => $ps);

my ($dist) = $ix->extra_distributions;

isa_ok($dist, 'XPAN::Dist');
is($dist->version, 1);
isnt($dist->origin, undef);
is_deeply(
  { map { $_->name => $_->version } $dist->dependencies },
  {
    'Scan::Test' => '0.10',
  },
  "dependencies ok (only matched simile)",
);

my $origin = $dist->origin;
my $dist_id = $dist->id;
($dist) = $ix->extra_distributions;
is($dist->origin, $origin, "dist did not change origin");
is($dist->id, $dist_id, "dist did not change id");

$ps->add_pins(
  {
    name => 'NoMeta',
    version => '0.02',
  },
);
$ps->save;

($dist) = $ix->extra_distributions;
isnt($dist->origin, $origin, "dist did change origin");
is($dist->version, 2, "dist increased version");

$ix->build;
my $fh = $ix->path->subdir('modules')->file('02packages.details.txt')->openr;
ok(
  (grep { /^XPAN::Task::Pinset::test\s+/ } <$fh>),
  "found Task in 02packages",
);
