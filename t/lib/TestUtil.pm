package TestUtil;

BEGIN {
  unshift @INC, './t/lib';
}

# Need a mock system class
sub a_system {
  require System;
  require Scheduler::Test;
  System->new({ scheduler_factory => 'Test' });
}

sub primitive_component {
  my ($name, $extra, $opts) = @_;
  $extra //= {};
  $opts //= {};

  my $c = Component::Primitive->new({
    name => $name,
    handler_generator => sub {},
    %$extra,
  });

  return $c;
}

sub compound_component {
  my ($name, $extra, $opts) = @_;

  my $c = Component::Primitive->new({
    name => $name,
    %$extra,
  });

  if ($opts->{inputs}) {
    my $in = ref $opts->{inputs} ? $opts->{inputs}
      : [ map { "input$_" } (1 .. $opts->{inputs}) ];
    $c->add_input($_) for @$in;
  }

  if ($opts->{outputs}) {
    my $in = ref $opts->{outputs} ? $opts->{outputs}
      : [ map "output$_", 1 .. $opts->{outputs} ];
    $c->add_output($_) for @$in;
  }

  if ($opts->{prescheduled}) {
    my $p = ref $opts->{prescheduled} ? $opts->{prescheduled}
      : [ map "subcomponent$_", 1 .. $opts->{prescheduled} ];
    for my $pc (@$p) {
      unless ($c->has_subcomponent($pc)) {
        $c->add_subcomponent($pc => trivial_component($pc));
      }
      $c->preschedule_component($pc);
    }
  }

  return $c;
}

sub trivial_component {
  Component->new({ name => $_[0], is_primitive => 1, handler_generator => sub {} });
}

1;

