use strict;
use warnings;

package XPAN::App::Command::testarchive;

use base qw(App::Cmd::Command);
use Path::Class ();

=head1 NAME

XPAN::App::Command::testarchive - set up a test archive

=cut

sub usage_desc { '%c testarchive %o <dst>' }

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("must run in XPAN checkout") unless -e 't/dist';
  $self->usage_error("invalid arguments") unless @$args == 1;
}

sub run {
  my ($self, $opt, $args) = @_;
  my $dir = Path::Class::dir($args->[0]);
  $dir->mkpath;
  require lib;
  lib->import("t/lib");
  require XPAN::Archiver::Test;
  my $arch = XPAN::Archiver::Test->new(path => $dir);
  $arch->log->info("test xpan built in $dir");
}

1;
