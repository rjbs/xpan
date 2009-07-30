use strict;
use warnings;

package XPAN::Pinset;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE pinsets (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(40) NOT NULL,
  UNIQUE(name)
);
END
}

__PACKAGE__->meta->setup(
  table => 'pinsets',

  columns => [
    id   => { type => 'integer', not_null => 1 },
    name => { type => 'varchar', length => 40, not_null => 1 },
  ],

  primary_key_columns => ['id'],

  unique_keys => ['name'],

  relationships => [
    pins => {
      type       => 'one to many',
      class      => 'XPAN::Pin',
      column_map => { id => 'pinset_id' },
    },
  ],
);
__PACKAGE__->make_manager_class;

sub change {
  my $self = shift;

  require XPAN::PinsetChange;
  return XPAN::PinsetChange->new(pinset => $self, @_);
}

1;
