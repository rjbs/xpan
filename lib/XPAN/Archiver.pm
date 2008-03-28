use strict;
use warnings;

package XPAN::Archiver;

use Carp ();
use Path::Class ();
use File::Copy ();
use XPAN::DB;
use XPAN::Config;
use XPAN::Context;
use Iterator::Simple qw(:all);
use CPAN::DistnameInfo;
use CPAN::Version;
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
    my ($self) = @_;
    my $class = $self->analyzer_class;
    eval "require $class; 1" or die $@;
    $class->new(archiver => $self);
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
  handles => [qw(log)],
  lazy => 1,
  default => sub {
    my ($self) = @_;
    XPAN::Context->new;
  },
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

# necessary for now in case someone uses XPAN::Dist, etc.
sub BUILD { shift->db } 

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

sub batch_auto_inject {
  my $self = shift;
  my $opt  = ref $_[-1] eq 'HASH' ? pop : {};
  my $iter = $self->iter_auto_inject([@_]);
  unless ($opt->{no_deps}) {
    $iter = $self->filter_follow_deps($iter);
  }
  my @res;
  while (my $res = $iter->next) {
    push @res, $res;
  }
  return @res;
}

sub auto_inject_one {
  my ($self, $arg) = @_;
  my ($url, $i_name);
  if (blessed $arg) {
    $url = $arg;
  } else {
    if ($arg =~ s/^(\w+):://) {
      $i_name = $1;
    }
    $url = URI->new("$arg");
  }
  $i_name ||= $url->scheme;

  my $injector = $self->injector_for($i_name);
  $i_name = $injector->name;

  $self->log->debug([ "%6s: injecting: %s", $i_name, $url ]);
  return $injector->inject($url);
}

sub iter_auto_inject {
  my $self = shift;
  imap { $self->auto_inject_one($_) } iflatten @_;
}

# follow dependencies 
sub filter_follow_deps {
  my $self = shift;
  iflatten imap {
    my $res = $_;
    my @r = $res;
    if (exists $res->warning->{unmet_deps}) {
      my @unmet = @{ $res->warning->{unmet_deps} };
      push @r, $self->filter_follow_deps(
        $self->iter_auto_inject(map { $_->{url} } @unmet)
      );
    }
    return iter \@r;
  } iflatten @_;
}

# we never want to try to fill these dependencies
my %SKIP_DEP = (
  perl   => 1,
  Config => 1,
);

sub filter_unmet_deps {
  my $self = shift;
  my $cpan = $self->injector_for('CPAN');
  imap {
    my $res = $_;
    return $res if $res->isa('XPAN::Result::Success::Already')
      or ! $res->is_success;
    for my $dep (grep { ! $_->matches($self) } $res->dist->dependencies) {
      # XXX: dependency policy should be configurable
      my $dep_url = $cpan->dist_url('cpan://package/' . $dep->name);
      next if $SKIP_DEP{$dep_url->name};
      push @{ $res->warning->{unmet_deps} ||= [] },
        { dep => $dep, url => $dep_url };
    }
    return $res;
  } iflatten @_;
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
  $dist->save;
  my $target = $dir->file($dist->path);
  eval { 
    $target->parent->mkpath;
    File::Copy::copy(
      $source,
      $target,
    );
  };
  if (my $e = $@) {
    $dist->delete;
    die "Could not copy $source -> $target: $@";
  }
  return $dist;
}

sub dists_by_name_iterator {
  my $self = shift;
  my $iter = $self->dist->manager->get_objects_iterator(
    sort_by => [ qw(name) ],
  );
  my $last = [ '' ];
  my $sort = sub {
    sort { CPAN::Version->vcmp($a->version, $b->version) } @_
  };
  return sub {
    DIST: {
      my $item = $iter->next;
      unless ($item) {
        if ($last->[0]) {
          my $return = $last;
          $last = [ '' ];
          return $sort->(@$return);
        }
        return;
      }
      unless ($last->[0] eq $item->name) {
        my $return = $last;
        $last = [ $item->name => [ $item ] ];
        # special case for the first time through
        if ($return->[0]) {
          return $sort->(@$return);
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
  my %p;
  if (ref $arg eq 'ARRAY') {
    $p{name}    = $arg->[0];
    $p{version} = $arg->[1];
  } elsif ($arg =~ /^\d+$/) {
    %p = ( id => $arg );
  }
  my $dist = $self->dist->new(%p);
  return $dist->load(speculative => 1) && $dist;
}

sub find_highest_version {
  my ($self, $type, $query) = @_;
  #use Data::Dumper; warn Dumper({ $type => $query });
  my @p = sort {
    CPAN::Version->vcmp($a->version, $b->version) ||
    ($type eq 'module' 
      ? CPAN::Version->vcmp($a->dist->version, $b->dist->version)
      : 0
    )
  } @{ $self->$type->manager->get_objects(
    query => $query
  ) };
  return $p[-1];
}

sub url_to_dist {
  my ($self, $url) = @_;
  blessed $url or $url = URI->new($url);
  if ($url->type eq 'dist') {
    return $self->find_dist([ $url->name, $url->version ])
      if defined $url->version;
    return $self->find_highest_version(
      dist => [ name => $url->name ],
    );
  }

  if ($url->type eq 'package') {
    my $pkg = $self->find_highest_version(
      module => [
        name => $url->name,
        defined $url->version
          ? (version => $url->version) : (),
      ],
    );
    return $pkg->dist;
  }

  if ($url->type eq 'id') {
    return $self->dist->manager->get_objects_iterator(
      query => [
        file      => $url->file_path,
        authority => $url->id,
      ],
    )->next;
  }

  die "unhandled url: $url";
}
    

      
1;
