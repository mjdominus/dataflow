package Component::Primitive;
use Moo;
use Scalar::Util qw(reftype);
use Carp 'croak';

with 'Component';

sub is_primitive { 1 }

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

# TODO: check opts
sub instantiate {
  my ($self, $opts) = @_;

  my $node = $self->new_node({
    handler   => $self->make_handler_function(@{$opts->{handler_args} // []}),
    name      => $opts->{name} // $self->generate_instance_name,
    system    => $opts->{system},
  });
}

# XXX Dummy -- fix this once you merge this with default-port branch
sub has_input_port {
  my ($self, $name) = @_;
  $name =~ /\A input \d+ \z/x;
}

# XXX Dummy -- fix this once you merge this with default-port branch
sub has_output_port {
  my ($self, $name) = @_;
  $name =~ /\A output \d+ \z/x;
}

sub has_port {
  my ($self, $name) = @_;
  $self->has_input_port($name) || $self->has_output_port($name);
}


1;
