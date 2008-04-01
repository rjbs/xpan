use strict;
use warnings;

package XPAN::Pin;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE pins (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  pinset_id INTEGER NOT NULL,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20),
  manual INTEGER NOT NULL DEFAULT 0,
  install_reason TEXT,
  hard_pin_reason TEXT,
  UNIQUE(pinset_id, name) 
);
END
}

__PACKAGE__->meta->setup(
  table => 'pins',

  columns => [
    id              => { type => 'integer', not_null => 1 },
    pinset_id       => { type => 'integer', not_null => 1 },
    name            => { type => 'varchar', length   => 100, not_null => 1 },
    version         => { type => 'varchar', length   => 20 },
    manual          => { type => 'integer', not_null => 1, default => 0 },
    install_reason  => { type => 'text' },
    hard_pin_reason => { type => 'text' },
  ],

  primary_key_columns => ['id'],

  unique_keys => [ [ qw(pinset_id name) ] ],

  foreign_keys => [
    pinset => {
      class => 'XPAN::Pinset',
      key_columns => { pinset_id => 'id' },
    },

    dist => {
      class => 'XPAN::Dist',
      key_columns => { name => 'name', version => 'version' },
    },
  ],
);
__PACKAGE__->make_manager_class;

sub as_string {
  my $self = shift;
  return sprintf '<pin name=%s version=%s>',
    $self->name,
    $self->version,
  ;
}

sub url {
  my ($self) = @_;
  require URI;
  return URI->new(sprintf 'xpan://pin/%s/%s', $self->name, $self->version);
}

1;
