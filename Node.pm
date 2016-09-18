package Node;
use Moo;
use Util;
use Scalar::Util qw(reftype);
use namespace::clean;

#
# A single primitive network such as an adder
#

sub is_primitive { 1 }

has debug => (
  is => 'rw',
  default => 0,
);

# Mainly for issuing announcements
has system => (
  is => 'ro',
  isa => sub { $DB::single=1; is_a($_[0], "System") },
  required => 1,
);

has name => (
  is => 'rw',
  isa => sub { defined($_[0]) && ! defined ref $_[0] },
  required => 1,
);

has handler => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "CODE" },
  required => 1,
);

# Hash mapping input names to TokenQueues
has input => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

# polymorphic with Network::attach_input
sub attach_input {
  my ($self, $token_queue, $name) = @_;
  $name //= $self->gen_port_name("input");
  $self->input->{$name} = $token_queue;
}

# Hash mapping output names to TokenQueues
has output => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

# polymorphic with Network::attach_output
sub attach_output {
  my ($self, $token_queue, $name) = @_;
  $name //= $self->gen_port_name("output");
  $self->output->{$name} = $token_queue;
}

sub notify {
  my ($self) = @_;
  $self->system->schedule($self);
}

sub source_node { $_[0] }
sub target_node { $_[0] }

sub activate {
  my ($self) = @_;
  $self->announce(sprintf "%s: activating", $self->name);
  $self->handler->($self, $self->input, $self->output);
}

sub announce {
  my ($self, @msg) = @_;
  $self->system->announce($self->name, @msg) if $self->debug;
}

1;
