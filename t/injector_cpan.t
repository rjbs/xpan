use strict;
use warnings;

use Test::More 'no_plan';
use XPAN::Injector::CPAN;
use XPAN::Analyzer;

my $i = XPAN::Injector::CPAN->new;
my $a = XPAN::Analyzer->new;
my $d;

is_deeply(
  $d = $a->analyze($i->arg_to_filename('Package-Generator-0.02')),
  {
    name    => 'Package-Generator',
    version => '0.02',
    modules => [
      {
        name => 'Package::Generator',
        file => 'lib/Package/Generator.pm',
        version => '0.02',
      },
    ],
    dependencies => [
      {
        name => 'Test::More',
        version => '0',
        source => 'META.yml',
      },
      {
        name => 'Scalar::Util',
        version => '0',
        source => 'META.yml',
      },
    ],
  },
  "arg_to_filename by distname and version",
);

is_deeply(
  $d = $a->analyze($i->arg_to_filename('Package-Generator')),
  {
    name    => 'Package-Generator',
    version => '0.102',
    modules => [
      {
        name => 'Package::Generator',
        file => 'lib/Package/Generator.pm',
        version => '0.102',
      },
      {
        name => 'Package::Reaper',
        file => 'lib/Package/Reaper.pm',
        version => '0.102',
      }
    ],
    dependencies => [
      {
        name => 'Test::More',
        version => '0',
        source => 'META.yml',
      },
      {
        name => 'Scalar::Util',
        version => '0',
        source => 'META.yml',
      },
    ],
  },
  "arg_to_filename by distname without version",
);
