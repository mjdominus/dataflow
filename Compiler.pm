package Compiler;
use Moo;
use Util qw(is_a);
use namespace::clean;
use Library;

has library => (
  is => 'ro',
  isa => sub { is_a($_[0], 'Library') },
  required => 1,
);

sub load_file {
  my ($self, $component, $filename) = @_;
  open my($fh), "<", $filename
    or die "Couldn't open file '$filename': $!\n";
  return $self->load_spec($component, <$fh>);
}

sub load_spec {
  my ($self, $component, @spec) = @_;
  chomp(@spec);
  my $OK = 1;
  $OK &&= $self->load_line($component, $_) for @spec;
  return $OK;
}

my %line_handler = ('-' => \&handle_connection,
                    '*' => \&handle_component,
                    '!' => \&handle_schedule,
                    '=' => \&handle_interface,
                   );

sub load_line {
  my ($self, $component, $line) = @_;
  $line =~ s/#.*//;             # discard comments

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
  return $self->$handler($component, $line);
}

sub handle_connection {
  my ($self, $component, $line) = @_;
  my $BAD = 0;
  my @words = split /\s*-\s*/, $line;
  for my $i (0 .. $#words - 1) {
    my ($c1_name, $c1_interface_name) = $words[$i]   =~ /(\w+)(?:\[(\w+)\])?/;
    my ($c2_name, $c2_interface_name) = $words[$i+1] =~ /(\w+)(?:\[(\w+)\])?/;

    my $wire = {};

    if ($component->has_interface($c1_name)) {
      $wire->{source} = { own_interface => $c1_name, direction => 'input' };
    } else {
      $wire->{source} = { subnetwork => $c1_name, interface => $c1_interface_name };
    }

    if ($component->has_interface($c2_name)) {
      $wire->{target} = { own_interface => $c2_name, direction => 'output' };
    } else {
      $wire->{target} = { subnetwork => $c2_name, interface => $c2_interface_name };
    }

    $BAD++ unless $component->add_wire($wire);
  }
  return $BAD == 0;
}

sub handle_component {
  my ($self, $component, $line) = @_;
  my ($name, $funargs) = $line =~ /(\w+):\s*(.*)/;
  my ($spec_name, @args) = split /\s+/, $funargs;
  my $prototype = $self->library->find_component($spec_name);
  not defined $prototype and do {
    warn "Unknown component type '$spec_name' in component line '$line'\n";
    return;
  };
  $component->add_subcomponent($name, $prototype, \@args);
  return 1;
}

sub handle_schedule {
  my ($self, $component, $line) = @_;
  my $BAD = 0;
  my @names = split /\s+/, $line;
  for my $name (@names) {
    $BAD++ unless $component->preschedule_component($name);
  }
  return $BAD == 0;
}

sub handle_interface {
  my ($self, $component, $line) = @_;
  my ($io, @names) = split /\s+/, $line;
  my $BAD = 0;
  my $cname = $component->name;

  for my $name (@names) {
    if ($io =~ /\A inputs? \z/x ) {
      if ($component->has_input($name)) {
        warn "Component $name: duplicate input '$name' in line '$line'\n";
        $BAD++;
      } else {
        $component->add_input($name);
      }
    } elsif ($io =~ /\A outputs? \z/x ) {
      if ($component->has_output($name)) {
        warn "Component $name: duplicate output '$name' in line '$line'\n";
        $BAD++;
      } else {
        $component->add_output($name);
      }
    } else {
      warn "interface line '$line' should begin with 'input' or 'output'\n";
      return;
    }
  }
  return $BAD == 0;
}

1;
