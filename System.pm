package System;
use Moo;
use Scalar::Util qw(reftype);
use namespace::clean;

has agenda => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "ARRAY" },
  default => sub { [] },
);

# Basic queue strategy: Just stick everything in an array
sub schedule {
  my ($self, @components) = @_;
  for my $component (@components) {
    print "System: scheduling " . $component->name . "\n";
  }
  push @{$self->agenda}, @components;
}

sub run {
  my ($self) = @_;
  1 while $self->run_one_step;
}

sub run_one_step {
  my ($self) = @_;
  my ($next) = pop @{$self->agenda};
  return unless defined $next;
  $self->announce("Running " . $next->name);
  $next->activate();
  return 1;
}

sub announce {
  my ($self, @msg) = @_;
  print "System: $_\n" for @msg;
}

1;
