package TestUtil;
BEGIN {
  unshift @INC, './t/lib';
}

# Need a mock system class
sub a_system {
  System->new({ scheduler_factory => 'Test' });
}

sub dummy_component {
  my ($name, $extra, $opts) = @_;
  $extra //= {};
  $opts //= {};

  my $c = Component->new({
    name => $name,
    is_primitive => 0,
    handler_generator => sub {},
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

package Scheduler::Test;

sub new { bless [ "Dummy Scheduler" ] => __PACKAGE__ }
sub schedule { }

1;
