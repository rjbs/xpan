use strict;
use warnings;

package XPAN::Injector::Git;

use Moose;
with qw(XPAN::Injector::VCS);

sub scheme { 'git' }

my %CHECKOUT = (
  tag => sub { $_[0] },
);

sub export_to_dir {
  my ($self, $url, $dir) = @_;
  my $path = $url->path;
  $url->path('') if $path;
  system("git clone $url $dir") and die "git clone $url $dir failed: $?";
  if ($path) {
    $path =~ s{^/+}{};
    my ($type, $val) = split m{/}, $path, 2;

    die "invalid path: $path" unless $CHECKOUT{$type};

    my $cmd = "git checkout " . $CHECKOUT{$type}->($val);
    system($cmd) and die "$cmd failed: $?";
  }

  Path::Class::dir($dir)->subdir('.git')->rmtree;
}

1;
