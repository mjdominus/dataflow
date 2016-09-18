#!/usr/bin/perl

use Test::More;
use Component;
use t::lib::TestUtil;

my $c1 = TestUtil::dummy_component("a");
my $c2 = TestUtil::dummy_component("b");


ok($c1);
ok($c2);
done_testing();
