package Network;
# Single INSTANCE of a compound component
# Most of its behavior is in Component::Compound

use Moo;
use Scalar::Util qw(reftype);
use Util;
use Carp qw(croak confess);
use namespace::clean;

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
  isa => sub { is_a($_[0], 'Component::Compound') },
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

sub interface {
  my ($self, $name) = @_;
  $self->input_interface($name) || $self->output_interface($name);
}

sub announce {
  my ($self, @msg) = @_;
  return unless $self->debug;
  $self->system->announce($self->name, @msg);
}

sub attach_input {
  my ($self, $q, $input_name, $direction) = @_;
  defined $direction or confess "misssing direction";
  $direction eq "source" or $direction eq "target"
    or confess "bad direction '$direction'";
  defined $input_name or confess("no input name");
  my $interface = $self->input_interface($input_name)
    or die sprintf "Can't find input interface '%s' of network '%s'\n",
      $input_name, $self->name;
  $interface->$direction($q);
  return $interface;
}

sub attach_output {
  my ($self, $q, $output_name, $direction) = @_;
  defined $direction or confess "misssing direction";
  $direction eq "source" or $direction eq "target"
    or confess "bad direction '$direction'";
  defined $output_name or confess("no output name");
  my $interface = $self->output_interface($output_name)
    or die sprintf "Can't find output interface '%s' of network '%s'\n",
      $output_name, $self->name;
  $interface->$direction($q);
  return $interface;
}

# What's the node at the source end of this interface chain?
sub source_node {
  my ($self, $interface_name) = @_;
  return $self->interface($interface_name);
}

sub target_node {
  my ($self, $interface_name) = @_;
  # TODO figure out how to snap token queue - interface chains
  return $self->interface($interface_name);
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

# A wire descriptor has { source => ... , target => ... }
# where the source and target values are one of:
# { subnetwork => subnet_name
#   interface => subnet_interface_name }
# { subnetwork => subnet_name }   # interface name will be inferred
# { own_interface => own_interface_name, direction => {input/output} }
sub build_wire {
  my ($self, $wire) = @_;

  my $source = $wire->{source};
  my $target = $wire->{target};

  # In the first draft, we'll always build a token queue
  # and attach it to the two points.
  # Later we'll optimize away chains of token queues somehow.
  my $q = TokenQueue->new;

  if ($source->{direction}) {
    my $attachment_point = $self->attach_input($q, $source->{own_interface}, "target");
    $q->source($attachment_point);
  } else {
    my $subnet = $self->subnetworks->{$source->{subnetwork}}
      or die "$source->{subnetwork}???";
    my $ifname = $source->{interface} // die "unimplemented";
    $subnet->attach_output($q, $ifname, "target");
    $q->source($subnet->source_node($ifname));
  }

  if ($target->{direction}) {
    my $attachment_point = $self->attach_output($q, $target->{own_interface}, "source");
    $q->target($attachment_point);
  } else {
    my $subnet = $self->subnetworks->{$target->{subnetwork}}
      or die "$target->{subnetwork}???";
    my $ifname = $target->{interface} // die "unimplemented";
    $subnet->attach_input($q, $ifname, "source");
    $q->target($subnet->target_node($ifname));
  }

}

1;
