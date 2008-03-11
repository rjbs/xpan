use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;
use XPAN::Analyzer;
use TestDist::Loader;

my $archiver = XPAN::Archiver::Test->new;
my $anz = $archiver->analyzer;

my $loader = TestDist::Loader->new;

my $no_meta     = $loader->file('NoMeta-0.02.tar.gz');
my $meta_over   = $loader->file('MetaOverride-1.00.tar.gz');
my $has_deps    = $loader->file('HasDeps-0.12.tar.gz');
my $broken_meta = $loader->file('BrokenMeta.tar.gz');

is_deeply(
  $anz->analyze("$no_meta"),
  { name => 'NoMeta', version => '0.02' },
  "analyzed without META.yml",
);

is_deeply(
  $anz->analyze("$meta_over"),
  {
    name => 'Meta-Override',
    version => '1.00',
    abstract => 'a dist where META.yml overrides the filename',
  },
  "analyzed with META.yml taking precedence",
);

is_deeply(
  $anz->analyze("$broken_meta"),
  {
    name => 'BrokenMeta',
    version => '0.01'
  },
  "analyzed with manual override for META.yml",
);

is_deeply(
  [ sort { $a->{name} cmp $b->{name} } @{
    $anz->analyze("$has_deps")->{dependencies} || []
  } ],
  [
    {
      name => 'Meta::Override',
      version => '1.01',
      source => 'META.yml',
    },
    {
      name => 'NoMeta',
      version => '0.01',
      source => 'META.yml',
    },
  ],
  "analyzed with dependencies",
);

is_deeply(
  { $anz->scan_for_modules("$no_meta") },
  {},
  "no packages in NoMeta",
);

is_deeply(
  { $anz->scan_for_modules($loader->file('Scan-Test-0.10.tar.gz') . "") },
  {
    modules => [
      {
        name => 'Scan::Test',
        version => '0.10',
        file => 'lib/Scan/Test.pm',
      },
      {
        name => 'Scan::Test::Inner',
        # this gets the outer package's version; that seems like a bug, but...
        version => '0.10',
        file => 'lib/Scan/Test.pm',
      },
    ],
  },
  "modules in Scan-Test",
);
