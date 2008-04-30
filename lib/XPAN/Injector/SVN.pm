use strict;
use warnings;

package XPAN::Injector::SVN;

use Moose;
with qw(XPAN::Injector::VCS);
use File::Temp ();

sub scheme { 'svn' }

sub export {
  my ($self, $url) = @_;

  my $dir = File::Temp::tempdir(CLEANUP => 1);

  my $auth = "";
  for (qw(username password)) {
    if ($self->config && $self->config->get($_)) {
      $auth = "--$_ " . $self->config->get($_);
    }
  }

  system("svn export $auth --force $url $dir >/dev/null")
    and die "svn export failed: $?";

  return $dir;
}

1;
