use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use XPAN::Archiver::Test;

my $archiver = XPAN::Archiver::Test->new(inject_tests => 0);
my $i = $archiver->injector_for('cpan');
my $a = $archiver->analyzer;
my $d;

for my $test (
  [ 'cpan://dist/Package-Generator',           'by distname (no version)' ],
  [ 'cpan://dist/Package-Generator/0.102',     'by distname and version' ],
  [ 'cpan://package/Package::Generator',       'by package (no version)' ],
  [ 'cpan://package/Package::Generator/0.102', 'by package and version' ],
) {
  my ($url, $label) = @$test;
  is_deeply(
    $d = $a->analyze($i->url_to_file($url)),
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
    "url_to_file $label ($url)"
  );
  for ($url, "CPAN::$url") {
    my $res = $archiver->auto_inject_one($_);
    ok($res->is_success, "inject: success");
    my $dist = $archiver->contains_dist_ok('Package-Generator', '0.102');
    is($dist->authority, 'cpan:RJBS', "correct authority");
    is($dist->origin, 'cpan://id/RJBS/Package-Generator-0.102.tar.gz',
      "correct origin");
    $dist->delete;
  }
}

  
