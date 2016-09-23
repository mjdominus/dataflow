#!/usr/bin/perl

use Test::More;
use Test::Deep;
use t::lib::TestUtil;
use Mock::TokenQueue;

my ($function_called);
sub function {
    $function_called++;
}

subtest activate_one_way => sub {
    for my $dir (qw(input output)) {
      my $odir = $dir eq "input" ? "output" : "input";
      my $if = Interface->new({ name => "test",
                                system => TestUtil::a_system(),
                                type => $dir,
                                "activate_$dir\_function" => \&function,
                                "activate_$odir\_function" => sub { die },
                              });
      if ($dir eq "input") { $if->target(Mock::TokenQueue->new) }
      else { $if->source(Mock::TokenQueue->new) }

      $if->activate;
      ok($function_called, "$dir function called");
    }
};

subtest activate_two_ways => sub {
  my $if = Interface->new({ name => "test",
                            system => TestUtil::a_system(),
                            type => "whatever",
                            "activate_input_function" => sub { die },
                            "activate_output_function" => sub { die },
                          });

  my ($in, $out) = (Mock::TokenQueue->new([17]), Mock::TokenQueue->new);
  $if->source($in);
  $if->target($out);

  $if->activate;
  ok($in->is_empty, "input now empty");
  is($out->size, 1, "output now has 1 token");
  is($out->peek_token, 17, "output token has the right value");

  note "now try with empty input";
  $if->activate;
  is($out->size, 1, "output still has 1 token");

  note "now try with full output";
  $in->put_token(23);
  $out->put_token(13) until $out->is_full;
  $if->activate;
  is($in->size, 1, "input still has 1 token");

};

# TODO - test Interface::activate_input and ::activate_output

done_testing();
