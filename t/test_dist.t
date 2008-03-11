#!perl
use strict;
use warnings;
use Test::More 'no_plan';
use File::Temp qw(tempdir);
use lib 't/lib';

use TestDist::Loader;

my $loader = TestDist::Loader->new;

my $dist = $loader->get_dist('MetaOverride-1.00');

is(
  $dist->filename,
  'MetaOverride-1.00.tar.gz',
  'correct filename',
);

is_deeply(
  [ keys %{$dist->files} ],
  [ 'META.yml' ],
  'correct files',
);

is(
  $dist->prefix,
  'MetaOverride-1.00',
  'correct prefix',
);

my $dir = tempdir(CLEANUP => 1);
eval { $dist->write($dir) };
is $@, "", "no error during write";
system("cd $dir && tar zxf " . $dist->filename);

my $meta =
  eval { YAML::Syck::LoadFile("$dir/" . $dist->prefix . "/META.yml") };
is $@, "", "no error when loading META.yml";
is_deeply(
  $meta,
  {
    name => 'Meta-Override',
    version => '0.100',
    abstract => 'a dist where META.yml overrides the filename',
  },
  'META.yml written correctly',
);
