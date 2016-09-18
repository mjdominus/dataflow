package TokenQueue;
use Moo;
use Scalar::Util qw(reftype);
use Carp ();
use Util;
use namespace::clean;

my @names = qw(Alpha Beta Gamma Delta Epsilon
               Zeta Eta Theta Iota Kappa
               Lambda Mu Nu Xi Omicron
               Pi Rho Sigma Tau Upsilon
               Phi Chi Psi Omega);

has max_size => (
  is => 'ro',
  default => 5,
);

has queue => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'ARRAY' },
  default => sub { [] },
);

my $x = "aaa";
has name => (
  is => 'ro',
  isa => sub { defined $_[0] && not defined ref $_[0] },
  default => sub { shift(@names) || "queue_" . $x++ },
);

sub size { 0 + @{$_[0]->queue} }
sub is_empty { $_[0]->size == 0 }
sub is_full { $_[0]->size == $_[0]->max_size }

sub croak {
  my ($self, $msg) = @_;
  $msg = $self->name . ": $msg";
  Carp::croak($msg);
}

sub put_token {
  my ($self, $token) = @_;
  warn "token queue ", $self->name, " gets token $token\n";
  $self->croak("is full") if $self->is_full;
  my $was_empty = $self->is_empty;
  push @{$self->queue}, $token;
  $self->target->notify if $was_empty;
}

sub get_token {
  my ($self) = @_;
  $self->croak("is empty") if $self->is_empty;
  my $was_full = $self->is_full;
  my $token = shift @{$self->queue};
  $self->source->notify if $was_full;
  return $token;
}

has source => (
  is => 'rw',
  isa => sub { is_a($_[0], "Node") || is_a($_[0], "Interface") },
);

has target => (
  is => 'rw',
  isa => sub { is_a($_[0], "Node") || is_a($_[0], "Interface") },
);

sub what_ho {
  my ($self) = @_;
  printf STDERR "TokenQueue %s reporting!\n\tSource is %s %s\n\tTarget is %s %s.\n",
    $self->name,
      ref($self->source), $self->source->name,
      ref($self->target), $self->target->name;
}

1;
