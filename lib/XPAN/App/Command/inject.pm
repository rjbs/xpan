use strict;
use warnings;

package XPAN::App::Command::inject;

use base qw(App::Cmd::Command);
use XPAN::Archiver;
use XPAN::Util qw(iter);

sub opt_spec {
  return (
    [ 'path|p=s', 'path to archive', { required => 1 } ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("at least one url is required") unless @$args;
}

sub run {
  my ($self, $opt, $args) = @_;
  
  my $arch = XPAN::Archiver->new(
    path    => $opt->{path},
  );

  my $arg_iter = (@$args == 1 and $args->[0] eq '-') 
    ? iter { defined(my $arg = <STDIN>) or return; chomp $arg; $arg }
    : iter { shift @$args };
    
  my $iter = $arch->auto_inject_iter_follow_deps($arg_iter);

  #$arch->db->do_transaction(sub {
    while (my $res = $iter->next) {
      if ($res->is_success) {
        if ($res->isa('XPAN::Result::Success::Already')) {
          $arch->log->debug([
            "\t-> already injected: %s", $res->dist->vname,
          ]);
        } else {
          $arch->log->info([
            "\t-> injected: %s", $res->dist->vname,
          ]);
        }
      } else {
        $arch->log->warning([
          "\t-> could not inject %s: %s",
          $res->url,
          $res->message,
        ]);
        die $res if $res->isa('XPAN::Result::Error::Fatal');
      }
    }
  #});
  #die $arch->db->error if $arch->db->error;
}

1;
