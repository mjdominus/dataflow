package Network;
# Single INSTANCE of a component
# Most of its behavior is in Component

use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Util;

use System;

has debug => (
  is => 'rw',
  default => 0,
);

has prototype => (
  is => 'ro',
  required => 1,
  isa => sub { is_a($_[0], 'Component') },
);

has handler => (
  is => 'ro',
  lazy => 1,
  isa => sub { reftype $_[0] eq "CODE" },
  builder => 'build_handler',
);

has handler_generator_arguments => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "ARRAY" },
  required => 1,
);

sub build_handler {
  my ($self) = @_;
  $self->prototype->make_handler_function(@{$self->handler_generator_arguments});
}

has instance_name => (
  is => 'ro',
  isa => sub { not defined ref $_[0] },
  default => sub { $_[0]->system->generate_component_name($_[0]->prototype->name) },
  lazy => 1,
);

# "Adder 'add3'"
sub name {
  my ($self) = @_;
  sprintf "%s '%s'", $self->prototype->name, $self->instance_name;
}

has port_name_counter => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { {} },
);

sub gen_port_name {
  my ($self, $prefix) = @_;
  $prefix //= "port";
  my $n = $self->port_name_counter->{$prefix}++;
  return "$prefix$n";
}

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
  required => 1,
);

# Hash mapping input names to TokenQueues
has input => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

sub attach_input {
  my ($self, $name, $token_queue) = @_;
  $name //= $self->gen_port_name("input");
  $self->input->{$name} = $token_queue;
}

# Hash mapping output names to TokenQueues
has output => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

sub attach_output {
  my ($self, $name, $token_queue) = @_;
  $name //= $self->gen_port_name("output");
  $self->output->{$name} = $token_queue;
}

sub notify {
  $_[0]->system->schedule($_[0]);
}

sub activate {
  my ($self) = @_;
  $self->handler->($self, $self->input, $self->output);
}

sub announce {
  my ($self, @msg) = @_;
  return unless $self->debug;
  $self->system->announce($self->name, @msg);
}

1;
