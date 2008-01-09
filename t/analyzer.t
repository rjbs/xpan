use strict;
use warnings;

use Test::More 'no_plan';
use XPAN::Analyzer;
use Path::Class;

my $anz = XPAN::Analyzer->new;

my $dist = dir('t/dist');
my $no_meta = $dist->file('NoMeta-0.02.tar.gz');
my $meta_over = $dist->file('MetaOverride-1.00.tar.gz');
my $has_deps  = $dist->file('HasDeps-0.12.tar.gz');

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
  [ sort { $a->{module_name} cmp $b->{module_name} } @{
    $anz->analyze("$has_deps")->{dependencies} || []
  } ],
  [
    {
      module_name => 'Meta::Override',
      module_version => '1.01',
      source => 'META.yml',
    },
    {
      module_name => 'NoMeta',
      module_version => '0.01',
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
  { $anz->scan_for_modules($dist->file('Scan-Test-0.10.tar.gz') . "") },
  {
    modules => [
      {
        name => 'Scan::Test',
        version => '0.10',
        file => 'Scan-Test-0.10/lib/Scan/Test.pm',
      },
      {
        name => 'Scan::Test::Inner',
        # this gets the outer package's version; that seems like a bug, but...
        version => '0.10',
        file => 'Scan-Test-0.10/lib/Scan/Test.pm',
      },
    ],
  },
  "modules in Scan-Test",
);
