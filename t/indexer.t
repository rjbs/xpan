use strict;
use warnings;
use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;
use CPAN::SQLite;

my $archiver = XPAN::Archiver::Test->new;

my $indexer = $archiver->indexer(-Latest);

$indexer->build;

my $cpan = CPAN::SQLite->new(
  CPAN => $indexer->path,
  db_dir => $indexer->path,
);
$cpan->index(setup => 1);

$indexer->each_distribution(sub {
  for my $module ($_->modules) {

    $cpan->query(
      mode => 'module',
      name => $module->name,
    );

    my $found = $cpan->{results};
    is($found->{mod_name}, $module->name,
      "found a result for " . $module->name);
  }
});
