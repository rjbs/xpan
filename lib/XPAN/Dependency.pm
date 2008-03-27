use strict;
use warnings;

package XPAN::Dependency;

use base qw(XPAN::DB::Object);

sub __create {
  return <<END;
CREATE TABLE dependencies (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  dist_id INTEGER NOT NULL,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(40) NOT NULL,
  source VARCHAR(40) NOT NULL,
  UNIQUE(dist_id, name)
);
END
}

__PACKAGE__->meta->setup(
  table   => 'dependencies',

  columns => [
    id      => { type => 'integer', not_null => 1 },
    dist_id => { type => 'integer', not_null => 1 },
    name    => { type => 'varchar', length   => 100, not_null => 1 },
    version => { type => 'varchar', length   => 40, not_null => 1 },
    source  => { type => 'varchar', length   => 40, not_null => 1 },
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

use CPAN::Version;
use Carp ();
use Scalar::Util ();

sub matching_modules {
  my ($self) = @_;
  
  require XPAN::Module;
  return grep {
    $self->matches($_)
  } @{ XPAN::Module->manager->get_objects(
    query => [
      name => $self->name,
    ],
    db => $self->db,
  ) };
}

sub matches {
  my ($self, $arg) = @_;

  return 1 if $self->name eq 'perl'; # XXX hack

  my $module;
  die "argument to matches() must be a Pinset, Pin, Dist, or Module (not $arg)"
    unless Scalar::Util::blessed($arg);

  if ($arg->isa('XPAN::Archiver')) {
    my $modules = $arg->module->manager->get_objects(
      query => [ name => $self->name ],
      db => $self->db,
    );
    return 0 < grep { $self->matches($_) } @$modules;
  }

  if ($arg->isa('XPAN::Pinset')) {
    my ($pin) = $arg->find_pins(
      require_objects => [ 'dist.modules' ],
      query => [
        'dist.modules.name' => $self->name,
      ],
    );
    return unless $arg = $pin;
  }

  if ($arg->isa('XPAN::Pin')) {
    $arg = $arg->dist;
  }

  if ($arg->isa('XPAN::Dist')) {
    #warn "looking for " . $self->name . " in " . $arg->name . "\n";
    ($arg) = $arg->find_modules({ name => $self->name });
    return unless $arg;
  }
  
  if ($arg->isa('XPAN::Module')) {
    # XXX see CPAN::Dist::unsat_prereqs -- we should also allow things like
    # this:
    # '> 5.005, !=5.9.1, !=5.9.2'
    return CPAN::Version->vcmp($arg->version || 0, $self->version) >= 0;
  } else {
    Carp::croak "unhandled argument to matches(): $arg";
  }

}

sub as_string {
  my ($self) = @_;
  return sprintf '<dep name=%s version=%s>',
    $self->name, $self->version;
}

1;
