package ComponentType;
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);

has debug => (
  is => 'rw',
  default => 0,
);

# "Adder"
has name => (
  is => 'ro',
  isa => sub { not defined ref $_[0] },
);

# Run when one of the input or output queues changes state
has handler_generator => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'CODE' },
  required => 1,
);

# If true, the handler generator is a function to build a handler
# If false, the handler is just a handler
has handler_generator_wants_arguments => (
  is => 'ro',
  default => sub { 0 },
);

sub make_handler_function {
  my ($self, @args) = @_;
  unless ($self->handler_generator_wants_arguments) {
    if (@args) {
      warn sprintf qq{Warning: Component type '%s' ignoring arguments "%s"\n},
        $self->name, join(" ", @args);
    }
    return $self->handler_generator;
  }

  unless (@args) {
    die sprintf qq{Component type '%s' missing required arguments\n},
        $self->name;
  }

  return $self->handler_generator->(@args);
}

1;
