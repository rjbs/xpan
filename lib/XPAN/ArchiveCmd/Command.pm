use strict;
use warnings;

package XPAN::ArchiveCmd::Command;

use base qw(App::Cmd::Command);

sub archiver { shift->app->archiver }

sub log { shift->app->log }

1;
