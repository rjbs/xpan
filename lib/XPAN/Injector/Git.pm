use strict;
use warnings;

package XPAN::Injector::Git;

use Moose;
with qw(XPAN::Injector::VCS);

sub scheme { 'git' }

sub export_to_dir {
  my ($self, $url, $dir) = @_;
  system("git clone $url $dir") and die "git clone $url $dir failed: $?";
  Path::Class::dir($dir)->subdir('.git')->rmtree;
}

1;
