use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;

my $archiver = XPAN::Archiver::Test->new(inject_tests => 0);
my $i = $archiver->injector_for('cpan');
my $a = $archiver->analyzer;
my $d;

is_deeply(
  $d = $a->analyze($i->url_to_file('cpan://dist/Package-Generator/0.102')),
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
  "url_to_file by distname and version",
);

is_deeply(
  $d = $a->analyze($i->url_to_file('cpan://dist/Package-Generator')),
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
  "url_to_file by distname without version",
);

$archiver->auto_inject('cpan://dist/Package-Generator');
my $dist = $archiver->contains_dist_ok('Package-Generator', '0.102');
is($dist->authority, 'cpan:RJBS', "correct authority");
is($dist->origin, 'cpan://RJBS/Package-Generator-0.102.tar.gz',
  "correct origin");
  
