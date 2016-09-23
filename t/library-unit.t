#!/usr/bin/perl

use Test::More;
use Library;
use System;
use t::lib::TestUtil;

my $lib = TestUtil::a_system()->library;
ok($lib);

subtest "basic library" => sub {
  for my $expected (qw(constant
                       adder subtracter multiplier divider
                       input output
                       select distribute merge split sink
                       comparator
                     )) {
    ok($lib->find_component($expected), $expected);
  }
};

done_testing();
