 #!/usr/bin/perl

use Test::More;
use Test::Deep;
use t::lib::TestUtil;
use Mock::TokenQueue;

my ($function_called);
sub function {
    $function_called++;
}

subtest activate => sub {
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

# TODO - test activation with both source and target

# TODO - test Interface::activate_input and ::activate_output

done_testing();
