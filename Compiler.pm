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

# Bleh, use dispatch table
sub load_line {
  my ($self, $system, $line) = @_;
  my $BAD = 0;
  return 1 unless $line =~ /\S/;
  if ($line =~ s/^-\s*//) {
    my @words = split /\s*-\s*/, $line;
    for my $i (0 .. $#words - 1) {
      my $c1 = $system->component($words[$i]);
      my $c2 = $system->component($words[$i+1]);
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
    my $component = Component->new({ name => $name, handler => $handler, system => $system });
    $system->add_component($name => $component);
  } elsif ($line =~ s/^!\s*//) {
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
    return if $BAD;
  }
  return 1;
}

1;
