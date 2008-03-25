use strict;
use warnings;

package XPAN::Util;

use Scalar::Util qw(blessed);
use Sub::Exporter -setup => {
  exports => [qw(iter_auto iter iter_merge iter_map)],
};

sub iter (&) { bless $_[0] => 'XPAN::Util::Iterator' }

sub iter_auto (@) {
  my @iter;
  for (@_) {
    if (blessed $_ and $_->isa('XPAN::Util::Iterator')) {
      push @iter, $_;
    } else {
      my @arg = $_;
      push @iter, iter { shift @arg };
    }
  }
  return iter_merge(\@iter);
}

sub iter_merge ($) {
  my $iters = shift;
  return iter { LOOP: {
    my $iter = $iters->[0] or return;
    my $rv = $iter->next;
    unless (defined $rv) {
      shift @$iters;
      redo;
    }
    return $rv;
  } };
}

sub iter_map (&$) {
  my ($code, $iter) = @_;
  return iter {
    local $_ = $iter->next;
    defined or return;
    return $code->();
  };
}

package XPAN::Util::Iterator;

use XPAN::Util -all;

sub next { shift->() }

sub prepend {
  return iter_merge([ iter_auto(@_), shift ]);
}

sub append {
  return iter_merge([ shift, iter_auto(@_) ]); 
}

1;
