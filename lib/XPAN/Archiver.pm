use strict;
use warnings;

package XPAN::Archiver;

use Carp ();
use Path::Class ();
use File::Copy ();
use XPAN::DB;
use XPAN::Config;
use CPAN::DistnameInfo;
use URI;

use Module::Pluggable::Object;

use Moose;
use Moose::Util::TypeConstraints;

find_type_constraint('Path::Class::Dir') ||
  class_type('Path::Class::Dir');

coerce 'Path::Class::Dir'
  => from 'Str'
  => via { Path::Class::dir($_) };

# injector plugins

sub default_injector_path { qw(XPAN::Injector) }

has extra_injector_paths => (
  is => 'ro',
  lazy => 1,
  isa => 'ArrayRef[Str]',
  auto_deref => 1,
  default => sub { [] },
);

has injector_pluggable => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    Module::Pluggable::Object->new(
      require => 1,
      search_path => [
        $self->extra_injector_paths,
        $self->default_injector_path,
      ],
    );
  },
);

has injector_class_map => (
  is => 'rw',
  lazy => 1,
  isa => 'HashRef',
  default => sub {
    my ($self) = @_;
    my %map;
    for my $i_class ($self->injector_pluggable->plugins) {
      unless ($i_class->can('does') and $i_class->does('XPAN::Injector')) {
        warn "injector plugin $i_class does not fulfill role XPAN::Injector\n";
        next;
      }
      $map{$i_class->scheme} ||= $i_class;
      $map{$i_class->name}   ||= $i_class;
    }
    return \%map; 
  },
);

has injectors => (
  is => 'rw',
  lazy => 1,
  isa => 'HashRef',
  default => sub { {} },
);

# analyzer

has analyzer => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $class = shift->analyzer_class;
    eval "require $class";
    die $@ if $@;
    $class->new;
  },
);

has analyzer_class => (
  is => 'ro',
  default => 'XPAN::Analyzer',
);

# context

has context => (
  is => 'ro',
  isa => 'XPAN::Context',
  required => 1,
  handles => [qw(log)],
);

# config

has config => (
  is => 'ro',
  isa => 'XPAN::Config',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    XPAN::Config->read_file($self->path->file('xpan.ini'));
  },
);

# other attributes

has path => (
  is => 'rw',
  isa => 'Path::Class::Dir',
  coerce => 1,
  required => 1,
);

has tmp => (
  is => 'ro',
  isa => 'Path::Class::Dir',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my $tmp = $self->path->subdir('tmp');
    $tmp->mkpath;
    return $tmp;
  },
);

has db => (
  isa => 'XPAN::DB',
  is => 'ro',
  lazy => 1,
  default => sub { shift->init_db },
);

sub init_db {
  my $self = shift;
  my $db_path = $self->path->file('xpan.db');
  XPAN::DB->register_db(
    driver => 'SQLite',
    database => $db_path,
  );
  my $exists = -e $db_path;
  my $db = XPAN::DB->new;
  $db->create_tables unless $exists;
  return $db;
}

# DB accessors

sub dist       { require XPAN::Dist;       'XPAN::Dist' }
sub module     { require XPAN::Module;     'XPAN::Module' }
sub pinset     { require XPAN::Pinset;     'XPAN::Pinset' }
sub pin        { require XPAN::Pin;        'XPAN::Pin' }
sub dependency { require XPAN::Dependency; 'XPAN::Dependency' }

sub do_transaction { shift->db->do_transaction(@_) }

my %related_loaded;
sub _related_object {
  my ($self, $default_base, $name, @rest) = @_;
  $name = "$default_base\::$name" if $name =~ s/^-//;
  unless ($related_loaded{$name}++) {
    eval "require $name";
    die $@ if $@;
  }
  return $name->new(
    @rest,
    archiver => $self,
  );
}

sub indexer  { shift->_related_object('XPAN::Indexer',  @_) }

sub injector_for {
  my ($self, $scheme) = @_;
  return $self->injectors->{$scheme} ||= do {
    my $i_class = $self->injector_class_map->{$scheme}
      or Carp::croak "no injector class found for $scheme://";
    $i_class->new(archiver => $self);
  };
}

# should this return something useful?
sub auto_inject {
  my $self = shift;
  my @args = @_;
  $self->do_transaction(sub {
    for (@args) {
      my ($url, $handler);
      if (blessed($_)) {
        $url = $_;
      } else {
        if (s/^(.+?):://) {
          $handler = $1;
        }
        $url = URI->new("$_");
      }
      $handler ||= $url->scheme;

      my $injector = $self->injector_for($handler);

      #warn "injecting: $injector => $url\n";
      $injector->inject($url);
    }
  });
  die $self->db->error if $self->db->error;
}

sub inject_one {
  my ($self, $source, $arg) = @_;

  unless ($source and %$arg) {
    Carp::croak "usage: \$archiver->inject_one(\$source, \\%arg)";
  }

  my $dir = $self->path->subdir('dist');
  $dir->mkpath;

  require XPAN::Dist;
  my $dist = $self->dist->new(
    %$arg,
    db => $self->db,
  );
  File::Copy::copy(
    $source,
    $dir->file($arg->{file}),
  );
  $dist->save;
  return $dist;
}

sub dists_by_name_iterator {
  my $self = shift;
  my $iter = $self->dist->manager->get_objects_iterator(
    sort_by => [ qw(name version) ],
  );
  my $last = [ '' ];
  return sub {
    DIST: {
      my $item = $iter->next;
      unless ($item) {
        if ($last->[0]) {
          my $return = $last;
          $last = [ '' ];
          return @$return;
        }
        return;
      }
      unless ($last->[0] eq $item->name) {
        my $return = $last;
        $last = [ $item->name => [ $item ] ];
        # special case for the first time through
        if ($return->[0]) {
          return @$return;
        } else {
          redo DIST;
        }
      }
      push @{ $last->[1] }, $item;
      redo DIST;
    }
  };
}

sub find_pinset {
  my ($self, $arg) = @_;
  return $self->pinset->new(
    ($arg =~ /^\d+$/
      ? (id => $arg)
      : (name => $arg)
    ),
  )->load;
}

sub find_dist {
  my ($self, $arg) = @_;
  
  if ($arg =~ /::/) {
    my ($name, $version) = split /\s+/, $arg;
    my $modules = $self->module->manager->get_objects(
      query => [
        name => $name,
        $version ? (version => $version) : (),
      ],
      db => $self->db,
      sort_by => 'version DESC',
    );

    unless (@$modules) {
      Carp::confess "can't find_dist, no matching modules: $arg";
    }

    return $modules->[0]->dist;
  }

  my $dinfo = CPAN::DistnameInfo->new("$arg.tar.gz");

  unless ($dinfo) {
    Carp::confess "can't parse argument as module or dist name: $arg";
  }

  my $dists = $self->dist->manager->get_objects(
    query => [
      name => $dinfo->dist,
      $dinfo->version ? (version => $dinfo->version) : (),
    ],
    db => $self->db,
    sort_by => 'version DESC',
  );

  unless (@$dists) {
    Carp::confess "can't find_dist, no matching dists: $arg";
  }

  return $dists->[0];
}
      
1;
