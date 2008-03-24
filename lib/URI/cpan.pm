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

package URI::cpan::_namever;
use base qw(URI::cpan);

sub NAME    () { 1 }
sub VERSION () { 2 }

sub name    { (split m{/}, shift->path)[NAME] }
sub version { (split m{/}, shift->path)[VERSION] }

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

sub authority { 
  my $self = shift;
  return $self->SUPER::authority unless @_;
  my $new = shift;
  Carp::croak "invalid cpanid: must be all uppercase letters (got '$new')"
    unless $new =~ /^[A-Z]+$/;
  return $self->SUPER::authority($new);
}
BEGIN { *cpanid = \&authority }

sub full_path {
  my ($self) = @_;
  my $id = $self->cpanid;
  return sprintf "authors/id/%s/%s/%s%s",
    substr($id, 0, 1),
    substr($id, 0, 2),
    $id,
    $self->path,
  ;
}

1;
