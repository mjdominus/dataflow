package Component::Compound;
use Moo;
use Scalar::Util qw(reftype);
use Carp 'croak';
use Interface;
use Network;
use Node;
use namespace::clean;

with 'Component';

sub is_primitive { 0 }

has network_factory => (
  is => 'ro',
  default => sub { "Network" },
  handles => { new_network => 'new' },
);


# This is a hash that maps names to
#   [ name, prototype, handler_args ]
# arrays
has subcomponents => (
  is => 'ro',
  default => sub { {} },
  isa => sub { reftype $_[0] eq 'HASH' },
);

sub add_subcomponent {
  my ($self, $name, $subcomponent, $handler_args) = @_;
  if ($self->has_subcomponent($name)) {
    die sprintf "%s: duplicate subcomponent named '%s'\n",
      $self->name, $name;
  }

  $self->subcomponents->{$name} =
    [ $name, $subcomponent, $handler_args ];
}

sub has_subcomponent {
  my ($self, $name) = @_;
  exists $self->subcomponents->{$name};
}

sub subcomponent_names {
  my ($self) = @_;
  keys %{$self->subcomponents};
}

sub subcomponent {
  my ($self, $name) = @_;
#  return $self if $name eq "SELF";
  my $sc = $self->subcomponents->{$name};
}

sub subcomponent_prototype {
  my ($self, $name) = @_;
  $self->subcomponent($name)->[1];
}

# Array of wire descriptors
#
# A wire descriptor has { source => ... , target => ... }
# where the source and target values are one of:
# { subnetwork => subnet_name
#   interface => subnet_interface_name }
# { subnetwork => subnet_name }   # interface name will be inferred
# { own_interface => own_interface_name, direction => {input/output} }

has wiring_diagram => (
  is => 'ro',
  default => sub { [] },
  isa => sub { reftype $_[0] eq 'ARRAY' },
);

# Except for the validity checking this does nothing but put the
# the wire description into the wiring diagram
sub add_wire {
  my ($self, $wire) = @_;

  croak "Malformed wire: missing source" unless $wire->{source};
  croak "Malformed wire: missing target" unless $wire->{target};

  my $BAD;
  $BAD++ unless $self->wire_is_okay(source => $wire->{source});
  $BAD++ unless $self->wire_is_okay(target => $wire->{target});

  if ($BAD) { return }
  else { push @{$self->{wiring_diagram}}, $wire;
         return $wire;
       }
}

sub wire_is_okay {
  my ($self, $st, $wire) = @_;
  my $BAD;

  my $io = $st eq "source" ? "input" :
           $st eq "target" ? "output" :
           die "unknown parameter wire_is_okay('$st',...): should be 'source' or 'target'";
  my $has_io = "has_$io";

  my $oi = $io eq "output" ? "input" :
           $io eq "input"  ? "output" : die;
  my $has_oi = "has_$oi";

  my $name = $self->name;

  if ($wire->{own_interface}) {
    unless ($wire->{direction} eq $io) {
      warn "$name: $io wire direction is '$wire->{direction}', should be '$io'\n";
      $BAD++;
    }
    unless ($self->$has_io($wire->{own_interface})) {
      warn "$name: has no $io interface '$wire->{own_interface}'\n";
      $BAD++;
    }
  } elsif ($wire->{subnetwork}) {
    unless ($self->has_subcomponent($wire->{subnetwork})) {
      warn "$name: has no component named '$wire->{subnetwork}'\n";
      $BAD++;
    }
    unless (!defined $wire->{interface} ||
            $self->subcomponent_prototype($wire->{subnetwork})
                 ->$has_oi($wire->{interface})) {
      warn "$name: subcomponent '$wire->{subnetwork}' has no $oi interface '$wire->{interface}'\n";
      $BAD++;
    }
  } else {
    warn "%$name: malformed wire has neither subnetwork name nor own interface name\n";
    $BAD++;
  }

  return ! $BAD;
}

sub add_input_interface {
  my ($self, $name) = @_;
  die sprintf "%s: already has input named '%s'\n",
    $self->name, $name
      if $self->has_input_interface($name);
  push @{$self->input_interfaces}, $name;
}

# Array of input interface names
has input_interfaces => (
  is => 'ro',
  default => sub { [] },
  isa => sub { reftype $_[0] eq 'ARRAY' },
);

sub input_interface_list { @{$_[0]->input_interfaces} }

sub has_input_interface {
  my ($self, $name) = @_;
  return 1 if $name =~ /\A input \d* \z/x && $self->is_primitive;
  return scalar grep $_ eq $name, $self->input_interface_list;
}

# Array of output interface names
has output_interfaces => (
  is => 'ro',
  default => sub { [] },
  isa => sub { reftype $_[0] eq 'ARRAY' },
);

sub output_interface_list { @{$_[0]->output_interfaces} }

sub has_output_interface {
  my ($self, $name) = @_;
  return 1 if $name =~ /\A output \d* \z/x && $self->is_primitive;
  return scalar grep $_ eq $name, $self->output_interface_list;
}

sub add_output_interface {
  my ($self, $name) = @_;
  die sprintf "%s: already has output named '%s'\n",
    $self->name, $name
      if $self->has_output_interface($name);
  push @{$self->output_interfaces}, $name;
}

sub has_interface {
  my ($self, $name) = @_;
  $self->has_input_interface($name) || $self->has_output_interface($name);
}

has prescheduled_components => (
  is => 'ro',
  init_arg => undef,
  default => sub { {} },
);

sub preschedule_component {
  my ($self, $name) = @_;
  unless ($self->has_subcomponent($name)) {
    warn sprintf "%s: can't preschedule unknown component '%s'\n",
      $self->name, $name;
    return;
  }
  $self->prescheduled_components->{$name} = 1;
  return 1;
}

sub is_prescheduled_component {
  my ($self, $name) = @_;
  exists $self->prescheduled_components->{$name};
}

# TODO: check opts
# TODO: if no instance name supplied, generate one by appending $self->name
# and a sequence number
sub instantiate {
  my ($self, $opts) = @_;
  my $system = $opts->{system};

  my $instance =
    $self->new_network({
      instance_name => $opts->{instance_name} // join("." => $self->name, $opts->{name}),
      prototype     => $self,
      'system'      => $system,
    });

  for my $subcomponent_name ($self->subcomponent_names) {
    my ($name, $subcomponent_type, $handler_args)
      = @{$self->subcomponents->{$subcomponent_name}};
    $instance->add_subnetwork($subcomponent_name,
                              $subcomponent_type->instantiate({
                                instance_name         => $subcomponent_name,
                                handler_args          => $handler_args,
                                system                => $system,
                               }));
  }

  for my $interface_name (@{$self->input_interfaces}) {
    $instance->add_input_interface($interface_name,
                                   $self->new_interface({ name   => $interface_name,
                                                          system => $system,
                                                        }));
  }

  for my $interface_name (@{$self->output_interfaces}) {
    $instance->add_output_interface($interface_name,
                                    $self->new_interface({ name   => $interface_name,
                                                           system => $system,
                                                         }));
  }

  for my $wire_desc (@{$self->wiring_diagram}) {
    $instance->build_wire($wire_desc);
  }

  return $instance;
}

1;
