use strict;
use warnings;

package XPAN::Config;

use Moose;

has _data => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { {} },
);

my $DEFAULT = {
  'XPAN::Injector::CPAN' => {
    cpan_mirror    => 'http://www.cpan.org',
    backpan_mirror => 'http://backpan.perl.org',
  },
};

sub BUILD {
  my ($self) = @_;
  # will we ever want a totally empty, default-less config?
  unless (%{ $self->_data }) {
    $self->update($DEFAULT);
  }
}

use Config::INI::Reader;
sub read_file {
  my ($class, $file) = @_;
  return $class->new->update(Config::INI::Reader->read_file($file));
}

sub get {
  my ($self, $key) = @_;
  my $val = $self->_data->{$key};
  return $val unless ref $val eq 'HASH';
  return blessed($self)->new({ _data => $val });
}

sub update {
  my ($self, $hash) = @_;
  
  # we only ever need a second-level merging because that's all a .ini allows
  for my $s (keys %$hash) {
    my $d = $hash->{$s};
    @{ $self->_data->{$s} ||= {} }{keys %$d} = values %$d;
  }
  return $self;
}
    
1;
