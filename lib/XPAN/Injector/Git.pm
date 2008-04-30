use strict;
use warnings;

package XPAN::Injector::Git;

use Moose;
with qw(XPAN::Injector::VCS);

use File::Temp ();

sub scheme { 'git' }

sub export {
  my ($self, $url) = @_;
  my $ref = $url->fragment;
  $url->fragment(undef) if $ref;
  my $dir = File::Temp::tempdir(CLEANUP => 1) . "/export";
  system("git clone $url $dir") and die "git clone $url $dir failed: $?";
  if ($ref) {
    my $cmd = "git checkout $ref";
    system($cmd) and die "$cmd failed: $?";
  }

  Path::Class::dir($dir)->subdir('.git')->rmtree;
  return $dir;
}

1;
