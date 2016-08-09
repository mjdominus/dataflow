package System;
use Moo;
use Scalar::Util qw(reftype);
use namespace::clean;
use Handlers ();
use Util qw(attach);
use Component;
use TokenQueue;

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

################################
#
# Spec loader
# Move this to a module
#

sub load_file {
  my ($self, $filename) = @_;
  open my($fh), "<", $filename
    or die "Couldn't open file '$filename': $!\n";
  $self->load_spec(<$fh>);
  return $self;
}

sub load_spec {
  my ($self, @spec) = @_;
  chomp(@spec);
  my $OK = 1;
  $OK &&= $self->load_line($_) for @spec;
  exit 1 unless $OK;
  return;
}

# Bleh, use dispatch table
sub load_line {
  my ($self, $line) = @_;
  my $BAD = 0;
  return 1 unless $line =~ /\S/;
  if ($line =~ s/^-\s*//) {
    my @words = split /\s*-\s*/, $line;
    for my $i (0 .. $#words - 1) {
      my $c1 = $self->component($words[$i]);
      my $c2 = $self->component($words[$i+1]);
      not defined $c1 and do {
        warn "Unknown component '$words[$i]' in wiring line '$line'\n";
        $BAD++;
      };
      not defined $c2 and do {
        warn "Unknown component '$words[$i+1]' in wiring line '$line'\n";
        $BAD++;
      };
      return if $BAD;
      attach($c1, $c2);
    }
  } elsif ($line =~ s/^\*\s*//) {
    my ($name, $funargs) = $line =~ /(\w+):\s*(.*)/;
    my ($func, @args) = split /\s+/, $funargs;
    my $h_func = "Handlers::$func";
    no strict 'refs';
    not defined(&$h_func) and do {
      warn "Unknown handler function '$func' in definition of component '$name'\n";
      $BAD++;
    };
    return if $BAD;
    my $handler = @args ? $h_func->(@args) : \&$h_func;
    my $component = Component->new({ name => $name, handler => $handler, system => $self });
    $self->add_component($name => $component);
  } elsif ($line =~ s/^!\s*//) {
    my @names = split /\s+/, $line;
    for my $name (@names) {
      my $component = $self->component($name);
      if (defined $component) {
        $self->schedule($component);
      } else {
        warn "Unknown component '$component' in schedule line\n";
        $BAD++;
      };
    }
    return if $BAD;
  }
  return 1;
}

1;
