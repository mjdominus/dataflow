package Library;
# Registry of Components
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Component::Primitive;
use Handler;
use Util;

has debug => (
  is => 'rw',
  default => 0,
);

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
  required => 1,
);

has search_path => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "ARRAY" },
  default => sub { [ qw| ./component . | ] },
);

has catalog => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  builder => 'build_catalog',
  lazy => 1,
);

sub add_component {
  my ($self, $name, $cs) = @_;
  if (exists $self->catalog->{$name}) {
    die "Duplicate component '$name' in library";
  }
  $self->announce("adding spec for component $name");
  $self->catalog->{$name} = $cs;
}

has handler_class => (
  is => 'ro',
  default => sub { "Handler" },
);

has primitive_component_factory => (
  is => 'ro',
  default => sub { "Component::Primitive" },
);

has port_name_class => (
  is => 'ro',
  default => sub { "PortNames" },
);

has library_loader_factory => (
  is => 'ro',
  default => sub { "LibraryLoader" },
);

has component_library_file => (
  is => 'ro',
  default => "library.lib",
);

has library_loader => (
  is => 'ro',
  default => sub {
    $DB::single=1;
    $_[0]->library_loader_factory
                     ->new({ handler_class => $_[0]->handler_class }) },
  lazy => 1,
);

sub build_catalog {
  my ($self) = @_;
  my %catalog;
  my $handler_class = $self->handler_class;
  for my $name ($handler_class->handler_list) {
    my $handler = "$handler_class\::$name";
    my $wants_args = ($name =~ s/^make_//);
    { no strict 'refs';
      unless (defined &$handler) { die "Unknown handler function '$handler'" };
      $handler = \&$handler;
    }
    no strict 'refs';
    $catalog{$name} =
      $self->primitive_component_factory->new({
        name                              => $name,
        handler_generator                 => $handler,
        handler_generator_wants_arguments => $wants_args,
      });
  }
  return \%catalog;
}

# convert the spec to an argument hash for Component
sub spec_to_component_args {
  my ($self, $spec) = @_;
  my %args;

  $args{handler_generator_wants_arguments} = $spec->{reqs_args};
  $args{handler_generator}     = $self->_resolve_func($spec->{handler});
  $args{always_autoschedule}   = $spec->{autoschedule};
  $args{input_port_namespace}  = $self->port_name_class->namespace($spec->{nin});
  $args{output_port_namespace} = $self->port_name_class->namespace($spec->{non});
  $args{name}                  = $spec->{name};

  return \%args;
}

# Convert function name to function reference if possible
sub _resolve_func {
  my ($self, $func_name) = @_;
  my $func = do {
    no strict 'refs';
    if (defined &$func_name) {
      \&$func_name;
    } else {
      die "Can't resolve function '$func_name'";
    }};
  return $func;
}

my $instance_name_counter = 0;
sub find_component {
  my ($self, $name) = @_;
  $self->announce("Looking for component '$name' in catalog");
  my $known = $self->catalog->{$name};
  $self->announce("Found component '$name' in catalog") if $known;
  return $known if defined($known);
  return $self->load_component($name);
}

sub load_component {
  my ($self, $name) = @_;
  for my $dir (@{$self->search_path}) {
    my $file = "$dir/$name.ds";
    if (-e $file) {
      $self->announce("Found component definition $name in $file");
      $self->system->load_file($name, $file);
      return $self->catalog->{$name};
    }
  }
  die "Unknown component type '$name'\n";
}

sub announce {
  my ($self, @msg) = @_;
  $self->system->announce("Library", @msg) if $self->debug;
}

1;
