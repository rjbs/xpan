use strict;
use warnings;

package XPAN::DB::Object;

use base qw(Rose::DB::Object);
use XPAN::DB;

sub manager {
  my ($self) = @_;
  my $class = ref $self || $self;
  my $manager = "$class\::Manager";
  return $manager;
}

sub make_manager_class {
  my ($class) = @_;
  eval sprintf <<'END',
package %s::Manager;
use base qw(XPAN::DB::Object::Manager);
__PACKAGE__->make_manager_methods('%s');
END

    $class, $class->meta->table;
  die $@ if $@;
}

sub init_db { XPAN::DB->new }

1;
