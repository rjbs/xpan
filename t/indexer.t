use strict;
use warnings;
use Test::More skip_all => 'bug in CPAN::SQLite with empty modlist';
use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;
use CPAN::SQLite;

my $archiver = XPAN::Archiver::Test->new;

my $indexer = $archiver->indexer(-Latest);

$indexer->build;

my $cpan = CPAN::SQLite->new(
  CPAN   => $indexer->path,
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
    if ($module->is_inner_package) {
      (my $name = $module->file) =~ s{/}{::}g;
      $name =~ s/^lib:://;
      $name =~ s/\.pm$//;
      is($found->{mod_name}, $name,
        "found outer package name $name for $name");
    } else {
      is($found->{mod_name}, $module->name,
        "found a result for " . $module->name);
    }
  }
});
