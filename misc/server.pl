use strict;
use lib 'lib';

BEGIN {
  $ENV{CATALYST_ENGINE} ||= 'HTTP';
  $ENV{CATALYST_DEBUG}    = 1;
}

use Catalyst::Engine::HTTP;
use XPAN::Server;

XPAN::Server->run( 3000 => localhost => {
    # argv              => \@argv,
    # 'fork'            => $fork,
    # keepalive         => $keepalive,
    # restart           => $restart,
    # restart_delay     => $restart_delay,
    # restart_regex     => qr/$restart_regex/,
    # restart_directory => $restart_directory,
    # follow_symlinks   => $follow_symlinks,
} );

