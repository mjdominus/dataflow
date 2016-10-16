#!/usr/bin/perl

use Scalar::Util qw(reftype);
use Test::More;
use Test::Fatal;
use Test::Deep qw(!reftype); # Incompatible with Scalar::Util::reftype
use Component::Compound;
use t::lib::TestUtil;

subtest subcomponents => sub {
    my $c1 = TestUtil::compound_component("a");
    my $c2 = TestUtil::compound_component("b");

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
        my $c = TestUtil::compound_component("X", {}, { inputs => 2 });
        
        ok($c);
        ok(  $c->has_input_interface("input1"));
        ok(  $c->has_input_interface("input2"));
        ok(! $c->has_input_interface("input3"));
        cmp_deeply([$c->input_interface_list], bag(qw| input1 input2 |));

        ok(  $c->has_interface("input1"));
        ok(  $c->has_interface("input2"));
        ok(! $c->has_interface("input3"));
    };
    
    subtest outputs => sub {
        # This tests add_input
        my $c = TestUtil::compound_component("X", {}, { outputs => 2 });
        
        ok($c);
        ok(  $c->has_output_interface("output1"));
        ok(  $c->has_output_interface("output2"));
        ok(! $c->has_output_interface("output3"));
        cmp_deeply([$c->output_interface_list], bag(qw| output1 output2 |));

        ok(  $c->has_interface("output1"));
        ok(  $c->has_interface("output2"));
        ok(! $c->has_interface("output3"));
    };

};

subtest prescheduled => sub {
    # This call tests ->prescheduled_component
    my $c = TestUtil::compound_component("X", {}, { prescheduled => 2 });

    ok(  $c->is_prescheduled_component("subcomponent1"));
    ok(  $c->is_prescheduled_component("subcomponent2"));
    ok(! $c->is_prescheduled_component("subcomponent3"));
};

done_testing();
