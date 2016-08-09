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

has name => (
  is => 'ro',
  isa => sub { defined $_[0] && not defined ref $_[0] },
  default => sub { shift @names },
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
  $self->croak("is full") if $self->is_full;
  push @{$self->queue}, $token;
  $self->target->notify;
}

sub get_token {
  my ($self) = @_;
  $self->croak("is empty") if $self->is_empty;
  my $token = pop @{$self->queue};
  $self->source->notify;
  return $token;
}

has source => (
  is => 'ro',
  isa => sub { is_a($_[0], "Component") },
);

has target => (
  is => 'ro',
  isa => sub { is_a($_[0], "Component") },
);

1;
