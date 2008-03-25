use strict;
use warnings;

package URI::cpan;
use base qw(URI::_generic);
use Carp ();

sub _init {
  my $self = shift->SUPER::_init(@_);
  my $auth = $self->authority;
  unless ($auth) {
    Carp::croak "invalid URI::cpan: missing authority (in $self)";
  }

  my $class = "URI::cpan::$auth";
  if ($auth =~ /^[A-Z]+$/) {
    $class = "URI::cpan::author";
  }
  {
    no strict 'refs';
    if (@{ "$class\::ISA" }) {
      return bless $self, $class;
    } else {
      Carp::croak "invalid URI::cpan: invalid authority '$auth' (from $self)";
    }
  }
}

sub type { 'generic' }

package URI::cpan::_namever;
use base qw(URI::cpan);

sub NAME    () { 1 }
sub VERSION () { 2 }

sub name {
  my ($self, $new) = @_;
  return +(split m{/}, $self->path)[NAME] if @_ == 1;
  my $path = join '/', '', $new, grep { defined } $self->version;
  $self->path($path);
  return $self;
}

sub version {
  my ($self, $new) = @_;
  return +(split m{/}, $self->path)[VERSION] if @_ == 1;
  $self->path(join '/', '', $self->name, $new);
  return $self;
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

sub vname {
  my ($self) = @_;
  Carp::croak "cannot produce vname for url without version: $self"
    unless defined $self->version;
  return join $self->sep, (split m{/}, $self->path)[NAME, VERSION];
}

sub _sep { die }

package URI::cpan::dist;
use base qw(URI::cpan::_namever);
sub sep { '-' }

package URI::cpan::package;
use base qw(URI::cpan::_namever);
sub sep { ' ' }

package URI::cpan::author;
use base qw(URI::cpan);
use File::Basename ();
use URI::Escape ();

sub type { 'author' }

sub authority { 
  my $self = shift;
  return $self->SUPER::authority unless @_;
  my $new = shift;
  Carp::croak "invalid cpanid: must be all uppercase letters (got '$new')"
    unless $new =~ /^[A-Z]+$/;
  return $self->SUPER::authority($new);
}
BEGIN { *cpanid = \&authority }

sub filename {
  my ($self) = @_;
  return File::Basename::basename($self->path);
}

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
      grep { defined && length } split m{/}, $self->path,
  ;
}

1;
