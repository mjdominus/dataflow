#!/usr/bin/perl

use Scalar::Util qw(reftype);
use Test::More;
use Test::Fatal;
use Test::Deep qw(!reftype); # Incompatible with Scalar::Util::reftype
use Component::Primitive;
use t::lib::TestUtil;

subtest handler_function => sub {
    subtest wants_arguments => sub {
        my $gen = sub { my ($c) = @_; sub { $c } };
        my $c = TestUtil::primitive_component("component",
                                          { 
                                              handler_generator => $gen,
                                              handler_generator_wants_arguments => 1,
                                          });

        my $f = $c->make_handler_function(3);
        is(reftype($f), "CODE", "make_handler_function returns code");
        is($f->(), 3, "handler function return value");
        ok(exception { $c->make_handler_function() },
           "handler generator arguments are required");
    };

    subtest no_arguments => sub {
        my $gen = sub { 17 };
        my $c = TestUtil::primitive_component("component",
                                          { handler_generator => $gen,
                                            handler_generator_wants_arguments => 0,
                                          });

        my $f = $c->make_handler_function();
        is(reftype($f), "CODE", "make_handler_function returns code");
        is($f->(), 17, "handler function return value");
    };
};

subtest io => sub {
    subtest primitive_default_io => sub {
        my $c = TestUtil::primitive_component("P");
        ok($c);
        ok(  $c->has_input_port("input23"));
        ok(! $c->has_input_port("output23"));
        ok(! $c->has_input_port("potato"));
        ok(  $c->has_output_port("output23"));
        ok(! $c->has_output_port("input23"));
        ok(! $c->has_output_port("potato"));

        ok(  $c->has_port("input23"));
        ok(  $c->has_port("output23"));
        ok(! $c->has_port("potato"));
    };
};

done_testing();
