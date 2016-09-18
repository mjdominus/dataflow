package Library;
# Registry of Components
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Handler;
use Component;
use Util;

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
  required => 1,
);

has search_path => (
  is => 'ro',
  isa => sub { reftype $_[0] eq "ARRAY" },
  default => sub { [ qw| ./component . | ] },
);

has catalog => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'HASH' },
  builder => 'build_catalog',
  lazy => 1,
);

sub add_component_specification {
  my ($self, $name, $cs) = @_;
  if (exists $self->catalog->{$name}) {
    die "Duplicate component specification '$name' in library";
  }
  warn "Library: adding spec for component $name\n";
  $self->catalog->{$name} = $cs;
}

has handler_class => (
  is => 'ro',
  default => sub { "Handler" },
);

has component_specification_factory => (
  is => 'ro',
  default => sub { "Component" },
);

has component_factory => (
  is => 'ro',
  default => sub { "Network" },
);

sub build_catalog {
  my ($self) = @_;
  my %catalog;
  my $handler_class = $self->handler_class;
  for my $name ($handler_class->handler_list) {
    my $handler = "$handler_class\::$name";
    my $wants_args = ($name =~ s/^make_//);
    { no strict 'refs';
      unless (defined &$handler) { die "Unknown handler function '$handler'" };
      $handler = \&$handler;
    }
    no strict 'refs';
    $catalog{$name} =
      $self->component_specification_factory->new({
        is_primitive                      => 1,
        name                              => $name,
        handler_generator                 => $handler,
        handler_generator_wants_arguments => $wants_args,
      });
  }
  return \%catalog;
}

my $instance_name_counter = 0;
sub find_component {
  my ($self, $name) = @_;
  warn "Library: Looking for component '$name' in catalog\n";
  my $known = $self->catalog->{$name};
  warn "Library: Found component '$name' in catalog\n" if $known;
  return $known if defined($known);
  return $self->load_component($name);
}

sub load_component {
  my ($self, $name) = @_;
  for my $dir (@{$self->search_path}) {
    my $file = "$dir/$name.ds";
    if (-e $file) {
      warn "Found component definition $name in $file\n";
      $self->system->load_file($name, $file);
      return $self->catalog->{$name};
    }
  }
  die "Unknown component type '$name'\n";
}

1;
__DATA__

