package Scheduler::Queue;
use Moo;
use Scalar::Util qw(reftype);
use Util;
use namespace::clean;

has debug => (
  is => 'rw',
  default => 0,
);

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
);

has agenda => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "ARRAY" },
  default => sub { [] },
);

has queue_type => (
  is => 'rw',
  isa => sub { /^(fifo|lifo|random)$/i },
  default => sub { 'lifo' },
);

has allow_duplicates => (
  is => 'rw',
  default => 0,
);

# Basic queue strategy: Just stick everything in an array
sub schedule {
  my ($self, @components) = @_;
  my $agenda = $self->agenda;
  if ($self->allow_duplicates) {
    for my $component (@components) {
      $self->announce("scheduling '" . $component->name . "'");
    }
    push @$agenda, @components;
  } else {
    COMPONENT: for my $component (@components) {
      for my $queued (@$agenda) {
        next COMPONENT if $queued == $component; # already queued, skip it
      }
      $self->announce("scheduling '" . $component->name . "'");
      push @$agenda, $component;
    }
  }
}

sub next_scheduled_component {
  my ($self) = @_;
  my $next;
  my $qt = $self->queue_type;
  my $agenda = $self->agenda;
  return unless @$agenda;
  if ($qt eq "fifo") {
    $next = pop @$agenda;
  } elsif ($qt = "lifo") {
    $next = shift @$agenda;
  } elsif ($qt = "random") {
    $next = splice @$agenda, int(rand(@$agenda)), 1;
  } else {
    die "Unknown queue_type '$qt'";
  }
  $self->announce("next component is '" . $next->name . "'");
  return $next;
}

sub announce_state {
  my ($self) = @_;
  my @components = map { $_->name } @{$self->agenda};
  $self->announce("complete state: " . join(", " => @components));
}

sub announce {
  my ($self, @msg) = @_;
  return unless $self->debug;
  $self->system->announce("scheduler", @msg);
}

1;

