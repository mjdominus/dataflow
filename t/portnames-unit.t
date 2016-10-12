#!/usr/bin/perl

use Test::More;
use Test::Deep;
use t::lib::TestUtil;
use PortNames;

subtest some => sub {
  my $some = PortNames::some("foo");
  is($some->(), "foo0");
  is($some->(qw/foo0/), "foo1");
  is($some->(qw/foo0 foo1/), "foo2");
  is($some->(qw/foo1/), "foo0");
  is($some->(qw/foo4 foo1 foo0/), "foo2");
};

subtest list => sub {
  my $list = PortNames::list("this", "that");
  is($list->(), "this");
  is($list->(qw/this/), "that");
  is($list->(qw/that/), "this");
  is($list->(qw/this that/), undef);
  is($list->(qw/that this/), undef);
};

done_testing();
