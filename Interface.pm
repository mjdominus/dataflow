package Interface;
use Moo;
use Scalar::Util qw(reftype);
use Util qw(is_a);
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

has name => (
  is => 'ro',
  isa => sub { not defined ref $_[0] },
  required => 1,
);

has source => (
  is => 'rw',
  isa => sub { is_a($_[0], "Node") || is_a($_[0], "Interface") },
  predicate => 'source_is_known',
);

has target => (
  is => 'rw',
  isa => sub { is_a($_[0], "Node") || is_a($_[0], "Interface") },
  predicate => 'target_is_known',
);

# Do we need this?
has type => (
  is => 'ro',
  isa => sub { $_[0] =~ /\A (input | output) \z/x },
  required => 1,
);

has activate_input_function => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "CODE" },
  default => sub { \&activate_input },
);

has activate_output_function => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "CODE" },
  default => sub { \&activate_output },
);

sub activate {
  my ($self) = @_;

  if ($self->source && $self->target) {
    if (! $self->source->is_empty && ! $self->target->is_full) {
      $self->target->put_token($self->source->get_token);
      $self->notify;
    }
  } elsif ($self->target) {
    if (! $self->target->is_full) {
      $self->target->put_token($self->activate_input_function->($self));
      $self->notify;
    }
  } elsif ($self->source) {
    if (! $self->source->is_empty) {
      $self->activate_output_function->($self, $self->source->get_token());
      $self->notify;
    }
  } else {
    die $self->type;
  }
}

sub activate_input {
  my ($self) = @_;

  print $self->name, "> ";
  chomp(my $input = <STDIN>);
  return if $input eq "done";
  $self->notify;
  return if $input eq "pass";
  $self->target->put_token($input);
}

sub activate_output {
  my ($self, $token) = @_;

  print "** ", $self->name, ": $token\n";
}

sub notify {
  my ($self) = @_;
  $self->system->schedule($self);
}

sub trace {
  my ($self, $opt) = @_;
  my $I = " |" x ($opt->{depth}//0);
  printf STDERR "* $I Interface %s\n", $self->name;
  my $t = $opt->{direction} eq "target" ? $self->target : $self->source;
  unless ($t) { print STDERR "  $I dead end.\n"; return; }
  $opt->{depth}++;
  $t->trace($opt);
  $opt->{depth}--;
}

1;
