use strict;
use warnings;

package XPAN::Injector::SVN;

use Moose;
with qw(XPAN::Injector::VCS);

sub scheme { 'svn' }

sub export_to_dir {
  my ($self, $url, $dir) = @_;

  my $auth = "";
  for (qw(username password)) {
    if ($self->config && $self->config->get($_)) {
      $auth = "--$_ " . $self->config->get($_);
    }
  }

  system("svn export $auth --force $url $dir >/dev/null")
    and die "svn export failed: $?";
}

1;
