#!/usr/bin/perl

use Node;

use t::lib::TestUtil;
use Mock::TokenQueue;
use System;

use Test::More;
use Test::Deep;

my $system = TestUtil::a_system();
my $node = Node->new({ system => $system,
                       handler => \&handler,
                       name => 'node',
                     });

my $handler_calls = 0;
ok($node, "node");
ok($node->is_primitive, "is primitive");

$node->attach_input(my $in = Mock::TokenQueue->new, "an_input");
$node->attach_output(my $out = Mock::TokenQueue->new, "some_output");

cmp_deeply($node->input, { an_input => ignore() }, "check input hash");
cmp_deeply($node->output, { some_output => ignore() }, "check output hash");

subtest activate => sub {
  $in->put_token(17);
  $node->activate;
  is($handler_calls, 1, "handler called");
  is($in->size, 0, "in queue emptied");
  is($out->size, 1, "out queue contains a token");
  is($out->get_token, 17, "out queue token");
};

done_testing();

sub handler {
  $handler_calls++;
  cmp_deeply(\@_, [$node, { an_input => $in }, { some_output => $out }], "handler args");

  my ($self, $in, $out) = @_;
  my ($i) = values %$in;
  my ($o) = values %$out;

  $o->put_token($i->get_token);
}

