use strict;
use warnings;

package XPAN::Module;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE modules (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20),
  file VARCHAR(110) NOT NULL,
  abstract TEXT,
  dist_id INTEGER NOT NULL,
  UNIQUE(dist_id, name)
);
END
}

__PACKAGE__->meta->setup(
  table   => 'modules',
  columns => [
    id       => { type => 'integer', not_null => 1 },
    name     => { type => 'varchar', length   => 100, not_null => 1 },
    version  => { type => 'varchar', length => 20 },
    file     => { type => 'varchar', length   => 110, not_null => 1 },
    dist_id  => { type => 'integer', not_null => 1 },
    abstract => { type => 'text' },
  ],

  primary_key_columns => ['id'],

  foreign_keys => [
    dist => {
      class => 'XPAN::Dist',
      key_columns => { dist_id => 'id' },
    },
  ],

  unique_keys => [ [ qw(dist_id name) ] ],
);
__PACKAGE__->make_manager_class;

sub is_inner_package {
  my ($self) = @_;
  (my $name = $self->name) =~ s{::}{/}g;
  $name .= ".pm";
  return not (
    # ReadKey.pm (in the dist_dir toplevel) and Term::ReadKey
    $self->file eq (split m{/}, $name)[-1] or
    # lib/Generic/Module.pm and Generic::Module
    $self->file =~ /\Q$name\E$/
  )
}

1;
