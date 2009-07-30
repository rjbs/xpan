use strict;
use warnings;

my $BASE;
BEGIN { $BASE = 'XPAN::Result' }

use Exception::Class (
  $BASE => {
    fields => [qw(url dist warning info)],
  },
  (map {
    ("$BASE\::$_" => { isa => $BASE })
  } qw(Success Info Error)),

  "$BASE\::Success::Already" => { isa => "$BASE\::Success" },
);
package XPAN::Result;
sub is_success { 0 }
sub is_error   { 0 }
sub is_info    { 0 }
XPAN::Result->Trace(0);

package XPAN::Result::Info;
sub is_info { 1 }

package XPAN::Result::Success;
sub is_success { 1 }

package XPAN::Result::Error;
sub is_error { 1 }

1;
