use strict;
use warnings;

package URI::cpan;
use base qw(URI::_generic);
use Carp ();

sub _init {
  my $self = shift->SUPER::_init(@_);
  my $class = ref($self);
  my $auth = $self->authority;
  unless ($auth) {
    Carp::croak "invalid $class: missing authority (in $self)";
  }

  my $subclass = "$class\::$auth";
  {
    no strict 'refs';
    if (@{ "$subclass\::ISA" }) {
      return bless $self, $subclass;
    } else {
      Carp::croak "invalid $class: invalid authority '$auth' (from $self)";
    }
  }
}

sub authority {
  my $self = shift;
  return $self->SUPER::authority unless @_;
  my $new = shift;
  my $ok = (split /::/, ref($self))[-1];
  Carp::croak "invalid type: must be '$ok'" unless $new eq $ok;
  return $self->SUPER::authority;
}

BEGIN { *type = \&authority }

sub _path_parts {
  die "override me";
}

sub _parse_parts {
  my $self = shift;
  return map { 
    my ($name, $length) = /^(\w+)(?:\[(\d+|\*)\])?$/;
    $length ||= 1;
    [ $name => $length ]
  } @_;
}

sub _splice_part {
  my ($self, $part, $new) = @_;
  my @parts = $self->_parse_parts($self->_path_parts);
  Carp::croak "invalid path part: '$part'"
    unless grep { $_->[0] eq $part } @parts;

  my (undef, @path) = split m{/}, $self->path;
  my $start = 0;
  for (@parts) {
    my ($name, $length) = @$_;
    $length = @path - $start if $length eq '*';
    if ($name ne $part) {
      $start += $length;
      if ($start > $#path) {
        if ($new) {
          push @path, @$new;
          $self->path(join '/', @path);
          return @$new;
        } else {
          return ();
        }
      }
      next;
    }
    if ($new) {
      splice(@path, $start, $length, @$new);
      $self->path(join '/', @path);
      return @$new;
    } else {
      return splice(@path, $start, $length);
    }
  }
  return ();
}

sub _path_part {
  my $self = shift;
  my $part = shift;
  my @p;
  if (@_) {
    (my $new = shift) =~ s{^/+}{};
    @p = $self->_splice_part($part => [split m{/}, $new]);
  } else {
    @p = $self->_splice_part($part);
  }
  my ($length) = map { $_->[1] } grep { $_->[0] eq $part }
    $self->_parse_parts($self->_path_parts);
  return join '/', ($length eq 1 ? () : ''), @p;
}

package URI::cpan::_namever;
use base qw(URI::cpan);

sub _path_parts { qw(name version) }

sub name    { shift->_path_part(name    => @_) }
sub version { shift->_path_part(version => @_) }

sub vname {
  my ($self) = @_;
  my $version = $self->version;
  Carp::croak "cannot produce vname for url without version: $self"
    unless defined $version;
  return join $self->sep, $self->name, $version;
}

sub _sep { die }

package URI::cpan::dist;
use base qw(URI::cpan::_namever);
sub sep { '-' }

package URI::cpan::package;
use base qw(URI::cpan::_namever);
sub sep { ' ' }

package URI::cpan::id;
use base qw(URI::cpan);
use URI::Escape ();

sub _path_parts {
  return qw(cpanid file_path[*]);
}

sub cpanid    { shift->_path_part(cpanid    => @_) }
sub file_path { Path::Class::file(shift->_path_part(file_path => @_)) } 

sub full_path     { shift->_full_path }
sub full_path_url { shift->_full_path(1) }

sub _full_path {
  my ($self, $escape) = @_;
  my $id = $self->cpanid;
  return join "/",
    map { $escape ? URI::Escape::uri_escape($_) : $_ }
      qw(authors id),
      substr($id, 0, 1),
      substr($id, 0, 2),
      $id,
      grep { defined && length } split m{/}, $self->file_path,
  ;
}

1;
