use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;

my $archiver = XPAN::Archiver::Test->new;
my $i = $archiver->injector_for('cpan');
my $a = $archiver->analyzer;
my $d;

is_deeply(
  $d = $a->analyze($i->url_to_file('cpan:///Package-Generator-0.02')),
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
  $d = $a->analyze($i->url_to_file('cpan:///Package-Generator')),
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
