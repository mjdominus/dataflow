#!/usr/bin/perl

use Test::More;
use Test::Deep;
use Test::Fatal;
use t::lib::TestUtil;
use TokenQueue;
use Mock::Node;


my $source = Mock::Node->new();
my $target = Mock::Node->new();

sub tq {
  my (%arg) = @_;
  my $tq = TokenQueue->new(\%arg);
  $tq->source($source);
  $tq->target($target);
  return $tq;
}

subtest "put, get" => sub {
  my $tq = tq();
  $tq->put_token(1);
  is($tq->get_token, 1);

  $tq->put_token(2);
  $tq->put_token(3);
  is($tq->get_token, 2);
  is($tq->get_token, 3);
};

subtest "size, is_full, is_empty" => sub {
  my $tq = tq(max_size => 2);

  my $xs = 0;

  ok($tq->is_empty, "empty");
  is($tq->size, $xs);

  for my $op (qw(put get put put get get)) {
    if ($op eq "get") {
      $tq->get_token;     $xs--;
    } else {
      $tq->put_token(1);  $xs++;
    }
    is($tq->size, $xs);
    ok($tq->is_full, "full?") if $xs == 2;
    ok($tq->is_empty, "empty?") if $xs == 0;
  }
};

subtest "overflow/underflow" => sub {
  my $tq = tq(max_size => 2);
  like( exception { $tq->get_token() }, qr/empty/, "underflow" );

  $tq->put_token(1);
  $tq->put_token(2);
  like( exception { $tq->put_token(3) }, qr/full/, "overflow" );
};

done_testing();
