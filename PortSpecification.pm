package PortSpecification;
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);

has name => (
  is => 'ro',
  isa => sub { ref $_[0] eq "" },
  required => 1,
);

has is_simple => (
  is => 'ro',
  default => sub { 1 },
);

has is_input => (
  is => 'ro',
  required => 1,
 );

sub is_output { not $_[0]->is_input }

sub io_matches {
  my ($self, $io) = @_;
  return $io =~ /^i/ && $self->is_input
      || $io =~ /^o/ && $self->is_output
}

1;

