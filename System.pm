package System;
use Moo;
use Scalar::Util qw(reftype);
use namespace::clean;
use Library;
use Compiler;
use Network;
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

has component_factory => (
  is => 'ro',
  default => sub { "Component" },
  handles => { new_component => 'new' },
);

has network => (
  is => 'rwp',
  isa => sub { is_a($_[0], 'Network') },
);

has compiler_factory => (
  is => 'ro',
  default => sub { "Compiler" },
  handles => { new_compiler => 'new' },
);

has compiler => (
  is => 'ro',
  lazy => 1,
  default => sub { $_[0]->new_compiler({ system => $_[0], library => $_[0]->library }) },
);

sub load_file {
  my ($self, @args) = @_;
  my $component = $self->new_component({ primitive => 0,
                                         name => 'ROOT',
                                         handler_generator => sub {},
                                       });
  $self->compiler->load_file($component, @args);

  my $network = $component->instantiate({
    instance_name => 'MAIN',
    system        => $self,
  });

  $self->_set_network($network);

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

sub schedule_prescheduled_components {
  my ($self) = @_;
  $self->network->schedule_prescheduled_components();
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
