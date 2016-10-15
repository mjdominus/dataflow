package Component;
use Moo::Role;
use Scalar::Util qw(reftype);
use Carp 'croak';
use namespace::clean;

requires 'instantiate';
requires 'is_primitive';

# "Adder"; "Increment"
has name => (
  is => 'ro',
  isa => sub { not defined ref $_[0] },
);

has instance_counter => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { {} },
);

sub generate_instance_name {
  my ($self) = @_;
  return join "" => $self->name,
    ++$self->instance_counter->{$self->name}
}


1;
