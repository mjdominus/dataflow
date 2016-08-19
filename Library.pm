package Library;
# Registry of ComponentSpecifications
use Moo;
use namespace::clean;
use Scalar::Util qw(reftype);
use Handler;
use ComponentSpecification;
use Util;

has system => (
  is => 'ro',
  isa => sub { is_a($_[0], "System") },
  required => 1,
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
  $self->{catalog}->{$name} = $cs;
}

has handler_class => (
  is => 'ro',
  default => sub { "Handler" },
);

has component_specification_factory => (
  is => 'ro',
  default => sub { "ComponentSpecification" },
);

has component_factory => (
  is => 'ro',
  default => sub { "Component" },
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
        name                              => $name,
        handler_generator                 => $handler,
        handler_generator_wants_arguments => $wants_args,
      });
  }
  return \%catalog;
}

my $instance_name_counter = 0;
sub make_component {
  my ($self, $spec_name, $name, @handler_generator_arguments) = @_;
  my $cs = $self->catalog->{$spec_name} or return;
  my $component = $self->component_factory
    ->new({ prototype => $cs,
            system => $self->system,
            handler_generator_arguments => \@handler_generator_arguments,
            instance_name => $name,
           });
  return $component;
}

1;
