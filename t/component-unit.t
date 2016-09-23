#!/usr/bin/perl

use Scalar::Util qw(reftype);
use Test::More;
use Test::Fatal;
use Test::Deep qw(!reftype); # Incompatible with Scalar::Util::reftype
use Component;
use t::lib::TestUtil;

subtest handler_function => sub {
    subtest wants_arguments => sub {
        my $gen = sub { my ($c) = @_; sub { $c } };
        my $c = TestUtil::dummy_component("component",
                                          { 
                                              handler_generator => $gen,
                                              handler_generator_wants_arguments => 1,
                                              is_primitive => 1,
                                          });

        my $f = $c->make_handler_function(3);
        is(reftype($f), "CODE", "make_handler_function returns code");
        is($f->(), 3, "handler function return value");
        ok(exception { $c->make_handler_function() },
           "handler generator arguments are required");
    };

    subtest no_arguments => sub {
        my $gen = sub { 17 };
        my $c = TestUtil::dummy_component("component",
                                          { handler_generator => $gen,
                                            handler_generator_wants_arguments => 0,
                                            is_primitive => 1,
                                          });

        my $f = $c->make_handler_function();
        is(reftype($f), "CODE", "make_handler_function returns code");
        is($f->(), 17, "handler function return value");
    };
};

subtest subcomponents => sub {
    my $c1 = TestUtil::dummy_component("a");
    my $c2 = TestUtil::dummy_component("b");

    $c1->add_subcomponent("subcomponent", $c2, [1,2,3]);
    ok($c1->has_subcomponent("subcomponent"));
    {
        my @names = $c1->subcomponent_names;
        cmp_deeply(\@names, [ "subcomponent" ], "subcomponent_names");
    }
    cmp_deeply($c1->subcomponent("subcomponent"),
               [ "subcomponent", $c2, [1,2,3] ],
               "subcomponent");
    is($c1->subcomponent_prototype("subcomponent"), $c2, "subcomponent_prototype");
};

subtest io => sub {
    subtest inputs => sub {
        # This tests add_output
        my $c = TestUtil::dummy_component("X", {}, { inputs => 2 });
        
        ok($c);
        ok(  $c->has_input("input1"));
        ok(  $c->has_input("input2"));
        ok(! $c->has_input("input3"));
        cmp_deeply([$c->input_list], bag(qw| input1 input2 |));

        ok(  $c->has_interface("input1"));
        ok(  $c->has_interface("input2"));
        ok(! $c->has_interface("input3"));
    };
    
    subtest outputs => sub {
        # This tests add_input
        my $c = TestUtil::dummy_component("X", {}, { outputs => 2 });
        
        ok($c);
        ok(  $c->has_output("output1"));
        ok(  $c->has_output("output2"));
        ok(! $c->has_output("output3"));
        cmp_deeply([$c->output_list], bag(qw| output1 output2 |));

        ok(  $c->has_interface("output1"));
        ok(  $c->has_interface("output2"));
        ok(! $c->has_interface("output3"));
    };

    subtest primitive_default_io => sub {
        my $c = TestUtil::dummy_component("P", { is_primitive => 1 });
        ok($c);
        ok(  $c->has_input("input23"));
        ok(! $c->has_input("output23"));
        ok(! $c->has_input("potato"));
        ok(  $c->has_output("output23"));
        ok(! $c->has_output("input23"));
        ok(! $c->has_output("potato"));

        ok(  $c->has_interface("input23"));
        ok(  $c->has_interface("output23"));
        ok(! $c->has_interface("potato"));
    };
};

subtest prescheduled => sub {
    # This call tests ->prescheduled_component
    my $c = TestUtil::dummy_component("X", {}, { prescheduled => 2 });

    ok(  $c->is_prescheduled("subcomponent1"));
    ok(  $c->is_prescheduled("subcomponent2"));
    ok(! $c->is_prescheduled("subcomponent3"));
};

done_testing();
