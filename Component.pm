package Component;
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Util;

use System;

has debug => (
  is => 'rw',
  default => 0,
);

has name => (
  is => 'ro',
  isa => sub { not defined ref $_[0] },
);

has name_counter => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { {} },
);

has default_input_port_name => (
  is => 'ro',
  isa => sub { ref $_[0] eq "" },
);

has default_output_port_name => (
  is => 'ro',
  isa => sub { ref $_[0] eq "" },
);

sub gen_name {
  my ($self, $prefix) = @_;
  die "missing prefix" unless defined $prefix;
  my $n = $self->name_counter->{$prefix}++;
  return "$prefix$n";
}

has port_specifications => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { {} },
);

sub port_specification {
  my ($self, $name) = @_;
  $self->port_specifications->{$name};
}

sub port_specification_list {
  my ($self) = @_;
  return %{$self->port_specifications};
}

sub add_port_specifications {
  my ($self, @pspecs) = @_;
  for my $pspec (@pspecs) {
    $self->port_specifications->{$pspec->name} = $pspec;
  }
}

sub port_name_is_valid {
  my ($self, $name, $io) = @_;
  my $pspec = $self->port($name);
  return $pspec && $pspec->io_matches($io) && $pspec;
}

# If there is a single input port spec, return it
# undef otherwise
sub unique_input_port_specification {
  my ($self) = @_;
  my $input_spec;
  for my $pspec ($self->port_specification_list) {
    if ($pspec->is_input) {
      if ($input_spec) { return }
      else { $input_spec = $pspec }
    }
  }
  return $input_spec;
}

# If there is a single input port spec, return it
# undef otherwise
sub unique_output_port_specification {
  my ($self) = @_;
  my $output_spec;
  for my $pspec ($self->port_specification_list) {
    if ($pspec->is_output) {
      if ($output_spec) { return }
      else { $output_spec = $pspec }
    }
  }
  return $output_spec;
}

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
);

# Hash mapping input names to TokenQueues
has input => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

sub attach_input {
  my ($self, $name, $token_queue) = @_;
  my $self_name = $self->name;

  $name //= $self->unique_input_port_specification //
    $self->default_input_port_name //
      die "Component $self_name requires input port name";
  die "Component $self_name does not have an input port named '$name'"
    unless $self->port_name_is_valid($name, "input");

  my $port_spec = $self->port_specification($name);
  my $port_name = $port_spec->is_simple ? $name : $self->gen_name($name);

  $self->input->{$port_name} = $token_queue;
}

# Hash mapping output names to TokenQueues
has output => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

# Bleah, duplicate code
sub attach_input {
  my ($self, $name, $token_queue) = @_;
  my $self_name = $self->name;

  $name //= $self->unique_output_port_specification //
    $self->default_output_port_name //
      die "Component $self_name requires output port name";
  die "Component $self_name does not have an output port named '$name'"
    unless $self->port_name_is_valid($name, "output");

  my $port_spec = $self->port_specification($name);
  my $port_name = $port_spec->is_simple ? $name : $self->gen_name($name);

  $self->output->{$port_name} = $token_queue;
}


# Run when one of the input or output queues changes state
has handler_function => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'CODE' },
  required => 1,
);

sub notify {
  $_[0]->system->schedule($_[0]);
}

sub activate {
  my ($self) = @_;
  $self->handler_function->($self, $self->input, $self->output);
}

sub announce {
  my ($self, @msg) = @_;
  return unless $self->debug;
  $self->system->announce($self->name, @msg);
}

1;
