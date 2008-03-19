use strict;
use warnings;

use Test::More 'no_plan';
use Test::Deep;

use File::Temp qw(tempdir);

use lib 't/lib';
use XPAN::Archiver::Test;
use XPAN::Analyzer;
use Module::Faker::Dist;

my $tmpdir = tempdir(CLEANUP => 1);

my $archiver = XPAN::Archiver::Test->new;
my $anz = $archiver->analyzer;

sub _mk_tgz {
  Module::Faker::Dist->from_file("t/dist/$_[0]")
                     ->make_archive({ dir => $tmpdir });
}

my $no_meta     = _mk_tgz('NoMeta-0.02.yaml');
my $meta_over   = _mk_tgz('MetaOverride-1.00.yaml');
my $has_deps    = _mk_tgz('HasDeps.yaml');
my $scan_test   = _mk_tgz('Scan-Test-0.10.yaml');
# my $broken_meta = _mk_tgz('BrokenMeta.yaml');

cmp_deeply(
  $anz->analyze($no_meta),
  { name => 'NoMeta', version => '0.02' },
  "analyzed without META.yml",
);

cmp_deeply(
  $anz->analyze($meta_over),
  {
    name     => 'Meta-Override',
    version  => '0.100',
    abstract => 'a dist where META.yml overrides the filename',
    modules  => ignore(),
  },
  "analyzed with META.yml taking precedence",
);

# is_deeply(
#   $anz->analyze("$broken_meta"),
#   {
#     name => 'BrokenMeta',
#     version => '0.01'
#   },
#   "analyzed with manual override for META.yml",
# );

cmp_bag(
  $anz->analyze($has_deps)->{dependencies},
  [
    {
      name    => 'Meta::Override',
      version => '1.01',
      source  => 'META.yml',
    },
    {
      name    => 'NoMeta',
      version => '0.01',
      source  => 'META.yml',
    },
  ],
  "analyzed with dependencies",
);

is_deeply(
  { $anz->scan_for_modules($no_meta) },
  { },
  "no packages in NoMeta",
);

is_deeply(
  { $anz->scan_for_modules($scan_test) },
  {
    modules => [
      {
        name    => 'Scan::Test',
        file    => 'lib/Scan/Test.pm',
        version => '0.10',
      },
      {
        # This gets the outer package's version; that seems like a bug, but
        # that is what mldistwatch does. -- hdp
        name    => 'Scan::Test::Inner',
        file    => 'lib/Scan/Test.pm',
        version => '0.10',
      },
    ],
  },
  "modules in Scan-Test",
);
