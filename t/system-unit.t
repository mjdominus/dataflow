#!/usr/bin/perl

use System;
use Test::More;
use t::lib::TestUtil;
require Scheduler::Test;

ok(TestUtil::a_system());

subtest "load_file" => sub {
  { local $TODO = "wait until there is a compiler test maybe?";
    ok(0);
  }
};

subtest "scheduler" => sub {
  for my $test (["Relative class" => "Test"],
                ["Relative class starting with 'Scheduler'" => "Scheduler::Test"],
                ["Absolute class" => "+AbsoluteScheduler"],
                ["Coderef" => sub { Scheduler::Test->new({ system => $_[0] }) }],
                ["Factory object" => SchedulerFactory->make_factory()],
               ) {
    my ($name, $spec) = @$test;
    subtest $name => sub {
      my $system = System->new({ scheduler_factory => $spec });
      my $scheduler = $system->scheduler;
      ok($scheduler);
      is($scheduler->system, $system, "scheduler reference to system");
    };
  }
};

subtest "run_one_step" => sub {
    { local $TODO = "dunno how yet";
    ok(0);
  }
};

done_testing();

################################################################
#
#

{
  package SchedulerFactory;

  sub make_factory {
    bless [] => __PACKAGE__;
  }

  sub new {
    require Scheduler::Test;
    shift;
    return Scheduler::Test->new(@_);
  }
}

{
  package AbsoluteScheduler;
  sub new { shift; Scheduler::Test->new(@_) }
}

