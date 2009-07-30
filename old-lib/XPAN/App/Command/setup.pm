use strict;
use warnings;

package XPAN::App::Command::setup;

use base qw(App::Cmd::Command);
use Path::Class ();

=head1 NAME

XPAN::App::Command::setup - set up an XPAN archive

=cut

sub usage_desc { '%c setup %o <dir>' }

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("exactly one argument is required") unless @$args == 1;
}

sub run {
  my ($self, $opt, $args) = @_;
  my $dir = Path::Class::dir($args->[0]);
  $dir->mkpath;
  
  require XPAN::Config;
  XPAN::Config->new->write_file($dir->file('xpan.ini'));
}

1;
