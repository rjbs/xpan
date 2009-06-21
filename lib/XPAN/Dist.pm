use strict;
use warnings;

package XPAN::Dist;

use base qw(XPAN::DB::Object);
use Path::Class ();

sub __create {
  return <<END;
CREATE TABLE dists (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20),
  abstract TEXT,
  file VARCHAR(110) NOT NULL,
  origin TEXT,
  authority TEXT NOT NULL,
  UNIQUE(name, version, authority)
);
END
}

__PACKAGE__->meta->setup(
  table   => 'dists',

  columns => [
    id        => { type => 'integer', not_null => 1 },
    name      => { type => 'varchar', length   => 100, not_null => 1 },
    version   => { type => 'varchar', length   => 20 },
    file      => { type => 'varchar', length   => 110, not_null => 1 },
    abstract  => { type => 'text' },
    origin    => { type => 'text' },
    authority => { type => 'text', not_null => 1 },
  ],

  primary_key_columns => ['id'],

  unique_keys => [
    [ qw(name version) ],
    [ qw(file) ],
  ],

  relationships => [
    modules => {
      type       => 'one to many',
      class      => 'XPAN::Module',
      column_map => { id => 'dist_id' },
    },

    dependencies => {
      type       => 'one to many',
      class      => 'XPAN::Dependency',
      column_map => { id => 'dist_id' },
    },

    pins => {
      type => 'one to many',
      class => 'XPAN::Pin',
      column_map => { name => 'name', version => 'version' },
    },
  ],
);
__PACKAGE__->make_manager_class;

sub vname {
  return sprintf "%s-%s", $_[0]->name, $_[0]->version;
}

sub path {
  my ($self) = @_;
  return Path::Class::file(
    split(/:/, $self->authority),
    $self->file,
  );
}

sub cpanid {
  my ($self) = @_;
  my $authority = $self->authority;
  my $cpanid;
  if ($authority =~ /^cpan:/) {
    (undef, $cpanid) = split /:/, $authority;
  } else {
    $cpanid = 'LOCAL';
  }
  return $cpanid;
}

sub url {
  my ($self) = @_;
  require URI;
  return URI->new(sprintf 'xpan://dist/%s/%s', $self->name, $self->version);
}

sub is_simile {
  my ($self, $package) = @_;
  (my $name = $package->name) =~ s/::/-/g;
  return $name eq $self->name;
}

1;
