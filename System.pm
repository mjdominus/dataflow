package System;
use Moo;
use Scalar::Util qw(reftype);
use namespace::clean;
use Library;
use Compiler;
use Component;
use TokenQueue;
use Scheduler::Queue;  # default scheduler
use Util qw(is_a);

has debug => (
  is => 'rw',
  default => 0,
);

has library_factory => (
  is => 'ro',
  default => sub { "Library" },
);

has library => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { $_[0]->library_factory->new({ system => $_[0]}) },
  handles => [ qw/add_component_specification component_specification/ ],
  lazy => 1,
);

has components => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { {} },
);

sub add_component {
  my ($self, $name, $component) = @_;
  if ($self->component($name)) {
    die "Duplicate component '$name'\n";
  }
  $self->components->{$name} = $component;
}

sub component {
  my ($self, $name) = @_;
  $self->components->{$name};
}

has component_instance_counter => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "HASH" },
  default => sub { {} },
);

sub generate_component_name {
  my ($self, $component_type) = @_;
  return join "" => $component_type, ++$self->component_instance_counter->{$component_type};
}

has compiler_factory => (
  is => 'ro',
  default => sub { "Compiler" },
);

has compiler => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->compiler_factory->new({ system => $_[0] }) },
);

sub load_file {
  my ($self, @args) = @_;
  $self->compiler->load_file(@args);
  return $self;
}

sub load_spec {
  my ($self, @args) = @_;
  $self->compiler->load_spec(@args);
  return $self;
}

has scheduler => (
  is => 'ro',
  isa => sub {
    $_[0]->can("schedule") && $_[0]->can("next_scheduled_component");
  },
  handles => [ qw(schedule next_scheduled_component) ],
  lazy => 1,
  builder => 'build_scheduler',
);

has scheduler_factory => (
  is => 'ro',
  required => 1,
);

sub build_scheduler {
  my ($self) = @_;
  my $factory = $self->scheduler_factory;
  my $scheduler;

  if (ref $factory eq "CODE") {
    $scheduler = $factory->($self);
  } elsif (ref $factory eq "") {
    $factory = "Scheduler::$factory" unless $factory =~ /^Scheduler::/;
    $scheduler = $factory->new({ system => $self });
  } else {
    $scheduler = $factory->new({ system => $self });
  }

  die "Couldn't build scheduler from factory '$factory'"
    unless defined $scheduler;

  return $scheduler;
}

sub run {
  my ($self) = @_;
  1 while $self->run_one_step;
}

sub run_one_step {
  my ($self) = @_;
  my $next = $self->next_scheduled_component;
  return unless defined $next;
  $self->sys_announce("running " . $next->name);
  $next->activate();
  return 1;
}

sub sys_announce {
  my ($self, @msg) = @_;
  $self->announce("System", @msg) if $self->debug;
}

sub announce {
  my ($self, $who, @msg) = @_;
  print "$who: $_\n" for @msg;
}

1;
