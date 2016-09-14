package Component;
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Carp 'croak';
use Interface;
use Network;
use Node;

# "Adder"
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

has is_primitive => (
  is => 'ro',
  isa => sub { $_[0] == 0 || $_[0] == 1 },
  default => 0,
);

# Run when one of the input or output queues changes state
has handler_generator => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'CODE' },
  required => 1,
);

has network_factory => (
  is => 'ro',
  default => sub { "Network" },
  handles => { new_network => 'new' },
);

has node_factory => (
  is => 'ro',
  default => sub { "Node" },
  handles => { new_node => 'new' },
);

has interface_factory => (
  is => 'ro',
  default => sub { "Interface" },
  handles => { new_interface => "new" },
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

 # Array of input interface names
has inputs => (
  is => 'ro',
  default => sub { [] },
  isa => sub { reftype $_[0] eq 'ARRAY' },
);

sub input_list { @{$_[0]->inputs} }

sub has_input {
  my ($self, $name) = @_;
  return 1 if $name =~ /\A input \d* \z/x && $self->is_primitive;
  return scalar grep $_ eq $name, $self->input_list;
}

sub add_input {
  my ($self, $name) = @_;
  die sprintf "%s: already has input named '%s'\n",
    $self->name, $name
      if $self->has_input($name);
  push @{$self->inputs}, $name;
}

# Array of output interface names
has outputs => (
  is => 'ro',
  default => sub { [] },
  isa => sub { reftype $_[0] eq 'ARRAY' },
);

sub output_list { @{$_[0]->outputs} }

sub has_output {
  my ($self, $name) = @_;
  return 1 if $name =~ /\A output \d* \z/x && $self->is_primitive;
  return scalar grep $_ eq $name, $self->output_list;
}

sub add_output {
  my ($self, $name) = @_;
  die sprintf "%s: already has output named '%s'\n",
    $self->name, $name
      if $self->has_output($name);
  push @{$self->outputs}, $name;
}

sub has_interface {
  my ($self, $name) = @_;
  $self->has_input($name) || $self->has_output($name);
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

sub is_prescheduled {
  my ($self, $name) = @_;
  exists $self->prescheduled_components->{$name};
}

sub instantiate {
  my ($self, $opts) = @_;
  # TODO check $opts


  if ($self->is_primitive) {
    return $self->instantiate_node($opts);
  } else {
    return $self->instantiate_network($opts);
  }
  die;
}

sub instantiate_node {
  my ($self, $opts) = @_;

  my $node = $self->new_node({
    handler   => $self->make_handler_function(@{$opts->{handler_args} // []}),
    prototype => $self,
    system    => $opts->{system},
  });
}

# TODO: if no instance name supplied, generate one by appending $self->name
# and a sequence number
sub instantiate_network {
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

  for my $interface_name (@{$self->inputs}) {
    $instance->add_input_interface($interface_name,
                                   $self->new_interface({ type   => "input",
                                                          name   => $interface_name,
                                                          system => $system,
                                                        }));
  }

  for my $interface_name (@{$self->outputs}) {
    $instance->add_output_interface($interface_name,
                                    $self->new_interface({ type   => "output",
                                                           name   => $interface_name,
                                                           system => $system,
                                                         }));
  }

  for my $wire_desc (@{$self->wiring_diagram}) {
    $instance->build_wire($wire_desc);
  }

  return $instance;
}


1;
