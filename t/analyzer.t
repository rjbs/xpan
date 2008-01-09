use strict;
use warnings;

use Test::More 'no_plan';
use XPAN::Analyzer;
use Path::Class;

my $zer = XPAN::Analyzer->new;

my $dist = dir('t/dist');
my $no_meta = $dist->file('NoMeta-0.02.tar.gz');
my $meta_over = $dist->file('MetaOverride-1.00.tar.gz');
my $has_deps  = $dist->file('HasDeps-0.12.tar.gz');

is_deeply(
  $zer->analyze("$no_meta"),
  { name => 'NoMeta', version => '0.02' },
  "analyzed without META.yml",
);

is_deeply(
  $zer->analyze("$meta_over"),
  {
    name => 'Meta-Override',
    version => '1.00',
    abstract => 'a dist where META.yml overrides the filename',
  },
  "analyzed with META.yml taking precedence",
);

is_deeply(
  [ sort { $a->{module_name} cmp $b->{module_name} } @{
    $zer->analyze("$has_deps")->{dependencies} || []
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
