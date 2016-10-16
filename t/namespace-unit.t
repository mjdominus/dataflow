#!/usr/bin/perl
use Test::More;
use Test::Deep;
use t::lib::TestUtil;
use Namespace::NameList;
use Namespace::NamePrefix;

subtest prefix => sub {
  my $prefix = Namespace::NamePrefix->new({ prefix => "foo" });
  subtest is_valid => sub {
    ok(  $prefix->is_valid("foo0"), "foo0");
    ok(  $prefix->is_valid("foo1"), "foo1");
    ok(  $prefix->is_valid("foo123"), "foo123");
    ok(! $prefix->is_valid("foo"), "foo");
    ok(! $prefix->is_valid("foo1a"), "foo1a");
    ok(! $prefix->is_valid("bar3"), "bar3");
  };

  subtest next_valid => sub {
    is($prefix->next_valid(), "foo0");
    is($prefix->next_valid(qw/foo0/), "foo1");
    is($prefix->next_valid(qw/foo0 foo1/), "foo2");
    is($prefix->next_valid(qw/foo1/), "foo0");
    is($prefix->next_valid(qw/foo4 foo1 foo0/), "foo2");
  };
};

subtest list => sub {
  my $list = Namespace::NameList->new({ name_list => [ "this", "that" ]});

  subtest is_valid => sub {
    ok(  $list->is_valid("this"), "this");
    ok(  $list->is_valid("that"), "that");
    ok(! $list->is_valid("the other"), "the other");
  };

  subtest next_valid => sub {
    is($list->next_valid(), "this");
    is($list->next_valid(qw/this/), "that");
    is($list->next_valid(qw/that/), "this");
    is($list->next_valid(qw/this that/), undef);
    is($list->next_valid(qw/that this/), undef);
  };
};

done_testing();
