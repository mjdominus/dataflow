package Namespace::NamePrefix;
use namespace::clean;
use Moo;
use Scalar::Util qw(reftype);
use List::Util qw(first);

with 'Namespace';

has prefix => (
  required => 1,
  is => 'ro',
  isa => sub { defined $_[0] &&  ! ref $_[0] },
);

has pat => (
  lazy => 1,
  is => 'ro',
  default => sub { my $prefix = $_[0]->prefix;
                   qr/\A \Q$prefix\E (\d+) \z /x; },
);

sub is_valid {
  my ($self, $name) = @_;
  $name =~ $self->pat;
}

sub next_valid {
  my ($self, @names) = @_;
  my $pat = $self->pat;
  my @used;
  $_ =~ $pat && ($used[$1] = 1) for @names;
  my $unused = first { ! $used[$_] } 0 .. 0+@used;
  return join "", $self->prefix, $unused;
}

1;
