use strict;
use warnings;

package XPAN::Injector::Git;

use Moose;
with qw(XPAN::Injector::VCS);

sub scheme { 'git' }

sub export_to_dir {
  my ($self, $url, $dir) = @_;
  my $ref = $url->fragment;
  $url->fragment(undef) if $ref;
  system("git clone $url $dir") and die "git clone $url $dir failed: $?";
  if ($ref) {
    my $cmd = "git checkout $ref";
    system($cmd) and die "$cmd failed: $?";
  }

  Path::Class::dir($dir)->subdir('.git')->rmtree;
}

1;
