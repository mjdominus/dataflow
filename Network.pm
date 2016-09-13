package Network;
# Single INSTANCE of a component
# Most of its behavior is in Component

use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Util;
use Carp qw(croak confess);

has debug => (
  is => 'rw',
  default => 0,
);

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
  required => 1,
);

has prototype => (
  is => 'ro',
  required => 1,
  isa => sub { is_a($_[0], 'Component') },
  handles => [ qw/ is_primitive is_prescheduled / ],
);

has instance_name => (
  is => 'ro',
  required => 1,
  isa => sub { defined $_[0] && ! defined ref $_[0] },
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

has subnetworks => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

sub has_subnetwork {
  my ($self, $name) = @_;
  exists $self->subnetworks->{$name};
}

sub add_subnetwork {
  my ($self, $name, $net) = @_;
  if ($self->has_subnetwork($name)) {
    die sprintf "%s: duplicate subnetwork named '%s'\n",
      $self->name, $name;
  }

  $self->subnetworks->{$name} = $net;
}

sub subnetwork {
  my ($self, $name) = @_;
  return $self->subnetworks->{$name};
}

has input_interfaces => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

sub add_input_interface {
  my ($self, $name, $iif) = @_;
  is_a($iif, "Interface")
    or die sprintf "Non-interface %s supplied as interface %s!\n",
      $iif, $name;
  # check for uniqueness of name here?
  $self->input_interfaces->{$name} = $iif;
}

sub input_interface {
  my ($self, $name) = @_;
  $self->input_interfaces->{$name};
}

has output_interfaces => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  default => sub { {} },
);

sub add_output_interface {
  my ($self, $name, $iif) = @_;
  is_a($iif, "Interface")
    or die sprintf "Non-interface %s supplied as interface %s!\n",
      $iif, $name;
  # check for uniqueness of name here?
  $self->output_interfaces->{$name} = $iif;
}

sub output_interface {
  my ($self, $name) = @_;
  $self->output_interfaces->{$name};
}

sub announce {
  my ($self, @msg) = @_;
  return unless $self->debug;
  $self->system->announce($self->name, @msg);
}

sub attach_input {
  my ($self, $q, $input_name) = @_;
  defined $input_name or confess("no input name");
  my $interface = $self->input_interface($input_name)
    or die sprintf "Can't find input interface '%s' of network '%s'\n",
      $input_name, $self->name;
  $interface->target($q);
  return $interface;
}

sub attach_output {
  my ($self, $q, $output_name) = @_;
  defined $output_name or confess("no output name");
  my $interface = $self->output_interface($output_name)
    or die sprintf "Can't find output interface '%s' of network '%s'\n",
      $output_name, $self->name;
  $interface->source($q);
  return $interface;
}

# What's the node at the source end of this interface chain?
sub source_node {
  my ($self, $interface_name) = @_;
  die "unimplemented\n";
}

sub target_node {
  my ($self, $interface_name) = @_;
  die "unimplemented\n";
}

sub schedule_prescheduled_components {
  my ($self) = @_;

  # Schedule all unattached input interfaces
  for my $input (values %{$self->input_interfaces}) {
    $input->notify;
  }

  for my $name (keys %{$self->subnetworks}) {
    my $subnet = $self->subnetwork($name);

    if ($subnet->is_primitive) {
      # Simple nodes get prescheduled if they are on the list
      if ($self->is_prescheduled($name)) {
        $self->system->schedule($subnet);
      }
    } else {
      # recurse into subnetworks looking for more nodes
      $subnet->schedule_prescheduled_components;
    }
  }
}

sub search {
  my ($self, $net_code, $node_code, $prefix) = @_;
  $prefix //= "";
  $net_code && $net_code->($self, "/$prefix");
  for my $subnet_name (keys %{$self->subnetworks}) {
    my $sub_prefix = join "/" => $prefix, $subnet_name;
    my $subnet = $self->subnetwork($subnet_name);
    if ($subnet->is_primitive) {
      $node_code && $node_code->($subnet, $sub_prefix);
    } else {
      $self->subnetwork($subnet_name)->search($net_code, $node_code, $sub_prefix);
    }
  }
}


1;
