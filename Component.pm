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

sub gen_name {
  my ($self, $prefix) = @_;
  $prefix //= "port";
  my $n = $self->name_counter->{$prefix}++;
  return "$prefix$n";
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
  $name //= $self->gen_name("input");
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
  $name //= $self->gen_name("output");
  $self->output->{$name} = $token_queue;
}


# Run when one of the input or output queues changes state
has handler => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'CODE' },
  required => 1,
);

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
