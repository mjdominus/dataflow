package Compiler;
use Moo;
use Util qw(attach);
use namespace::clean;

has system_factory => (
  is => 'rw',
  isa => sub { },
  default => 'System',
);

sub load_file {
  my ($self, $filename) = @_;
  open my($fh), "<", $filename
    or die "Couldn't open file '$filename': $!\n";
  return $self->load_spec(<$fh>);
}

sub load_spec {
  my ($self, @spec) = @_;
  chomp(@spec);
  my $system = $self->system_factory->new();
  my $OK = 1;
  $OK &&= $self->load_line($system, $_) for @spec;
  return $OK && $system;
}

my %line_handler = ('-' => \&handle_connection,
                    '*' => \&handle_component,
                    '!' => \&handle_schedule,
                   );

sub load_line {
  my ($self, $system, $line) = @_;

  return 1 unless $line =~ /\S/;
  unless ($line =~ /^\s*(\S)\s/) {
    warn sprintf "Malformed line starts with '%s'\n", substr($line, 0, 2);
    return;
  }
  my $c = $1;
  my $handler = $line_handler{$c} or do {
    warn "Unrecognized selector character '$c'\n";
    return;
  };
  $line =~ s/^\s*(\S)\s//;
  return $handler->($system, $line);
}

sub handle_connection {
  my ($system, $line) = @_;
  my $BAD = 0;
  my @words = split /\s*-\s*/, $line;
  for my $i (0 .. $#words - 1) {
    my ($c1_name, $c1_queue_name) = $words[$i]   =~ /(\w+)(?:\[(\w+)\])?/;
    my ($c2_name, $c2_queue_name) = $words[$i+1] =~ /(\w+)(?:\[(\w+)\])?/;
    my $c1 = $system->component($c1_name);
    my $c2 = $system->component($c2_name);
    $i == 0 && not defined $c1 and do {
      warn "Unknown component '$c1_name' in wiring line '$line'\n";
      $BAD++;
    };
    not defined $c2 and do {
      warn "Unknown component '$c2_name' in wiring line '$line'\n";
      $BAD++;
    };
    attach($c1_queue_name ? [$c1, $c1_queue_name] : $c1,
           $c2_queue_name ? [$c2, $c2_queue_name] : $c2,
          ) unless $BAD;
  }
  return $BAD == 0;
}

sub handle_component {
  my ($system, $line) = @_;
  my ($name, $funargs) = $line =~ /(\w+):\s*(.*)/;
  my ($func, @args) = split /\s+/, $funargs;
  my $h_func = "Handlers::$func";
  no strict 'refs';
  not defined(&$h_func) and do {
    warn "Unknown handler function '$func' in definition of component '$name'\n";
    return;
  };
  my $handler = @args ? $h_func->(@args) : \&$h_func;
  my $component = Component->new({ name => $name, handler => $handler, system => $system });
  $system->add_component($name => $component);
  return 1;
}

sub handle_schedule {
  my ($system, $line) = @_;
  my $BAD = 0;
  my @names = split /\s+/, $line;
  for my $name (@names) {
    my $component = $system->component($name);
    if (defined $component) {
      $system->schedule($component);
    } else {
      warn "Unknown component '$component' in schedule line\n";
      $BAD++;
    };
  }
  return $BAD == 0;
}

1;
