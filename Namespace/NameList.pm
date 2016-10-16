package Namespace::NameList;
use namespace::clean;
use Moo;
use Scalar::Util qw(reftype);
use List::Util qw(all first);

with 'Namespace';

has name_list => (
  required => 1,
  is => 'ro',
  isa => sub {
    reftype($_[0]) eq "ARRAY" && all { defined && ! ref } @{$_[0]};
  },
);

has name_hash => (
  lazy => 1,
  is => 'ro',
  default => sub { +{ map { $_ => 1 } $_[0]->names } },
);

sub names { @{$_[0]->name_list} }

sub is_valid {
  my ($self, $name) = @_;
  $self->name_hash->{$name};
}

sub next_valid {
  my ($self, @names) = @_;
  my %seen = map { $_ => 1 } @_;
  return first { ! $seen{$_} } $self->names;
}

1;
