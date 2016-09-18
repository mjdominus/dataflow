#!/usr/bin/perl

use Test::More;
use Test::Deep;
use Test::Fatal;
use t::lib::TestUtil;
use Handler;
use Mock::TokenQueue;

sub try {
  my ($f, $input, $output, $node) = @_;
  $output //= {};
  $node //= Mock::Node->new();

  my (%in, %out);
  while (my ($name, $tokens) = each %$input) {
    $in{$name} = Mock::TokenQueue->new($tokens);
  }
  while (my ($name, $tokens) = each %$output) {
    $out{$name} = Mock::TokenQueue->new($tokens);
  }

  $f->($node, \%in, \%out);
  return [\%out, \%in];
}

sub test_binop {
  my ($f, $name, $op) = @_;
  my $empty = noclass([]);
  subtest "binary operator '$name'" => sub {
    cmp_deeply(try($f, { input0 => [], input1 => [7] }, { output0 => [] }),
               [ { output0 => $empty }, { input0 => $empty,
                                          input1 => noclass([7]) } ],
               "empty input0");

    cmp_deeply(try($f, { input0 => [5], input1 => [] }, { output0 => [] }),
               [ { output0 => $empty }, { input0 => noclass([5]),
                                          input1 => $empty } ],
               "empty input1");

    cmp_deeply(try($f, { input0 => [5], input1 => [7] }, { output0 => [1..5] }),
               [ { output0 => noclass([1..5]) }, { input0 => noclass([5]),
                                                   input1 => noclass([7]) } ],
               "full output");

    cmp_deeply(try($f, { input0 => [7], input1 => [5] }, { output0 => [] }),
               [ { output0 => noclass([$op->(7,5)]) }, ignore() ],
               "forward $name");

    cmp_deeply(try($f, { input0 => [5], input1 => [7] }, { output0 => [] }),
               [ { output0 => noclass([$op->(5,7)]) }, ignore() ],
               "reverse $name");
  };
}

# Todo: add is not actually a binop, it is a multiop, and can take multiple inputs
test_binop(\&Handler::adder, "add", sub { $_[0] + $_[1] });

subtest comparator => sub {
  # let's only test <
  # the others are only trivially difference
  for my $test ([3,7,1], [3,3,0], [7,3,0]) {
    my $i0 = Mock::TokenQueue->new([$test->[0]]);
    my $i1 = Mock::TokenQueue->new([$test->[1]]);
    my $out = Mock::TokenQueue->new();

    Handler::make_comparator("<")->(
      Mock::Node->new(),
      { input0 => $i0,
        input1 => $i1,
      },
      { output0 => $out },
     );

    is($out->get_token, $test->[2], "comparison $test->[0] < $test->[1] is $test->[2]");
  }
};

subtest constant => sub {
  subtest "normal operation" => sub {
    my $node = Mock::Node->new;
    my $tq = Mock::TokenQueue->new;
    Handler::make_constant(17)->($node, {}, { out => $tq });
    cmp_deeply($tq, noclass([17]), "constant put on output");
    is($node->{notifications}, 1, "node renotified");
  };
  subtest "full output" => sub {
    my $node = Mock::Node->new;
    my $tq = Mock::TokenQueue->new([1..5]);
    ok(! exception { Handler::make_constant(17)->($node, {}, { out => $tq }) },
       "doesn't overflow output queue");
    is($node->{notifications}, 0, "no renotification");
  };
};

subtest distribute => sub {
  for my $bool (0, 1) {
    subtest "boolean $bool value" => sub {
      my $in = Mock::TokenQueue->new([7]);
      my @out = (Mock::TokenQueue->new(), Mock::TokenQueue->new());
      my $control = Mock::TokenQueue->new([$bool]);
      Handler::distribute(
        Mock::Node->new(),
        { input => $in, control => $control },
        { output_t => $out[1], output_f => $out[0] });
      ok($in->is_empty, "data input is empty");
      ok($control->is_empty, "control is empty");
      ok($out[1-$bool]->is_empty, "unselected output is empty");
      is($out[$bool]->size, 1, "one token on selected output");
      is($out[$bool]->get_token, 7, "token value");
    }
  }

  # Todo: test quiet return on full outputs, empty inputs
};

test_binop(\&Handler::divider, "divide", sub { $_[0] / $_[1] });

subtest input => sub {
 TODO: {
    local $TODO = "current implementation requires stdin";
    pass();
  }
};

subtest "merge" => sub {
  for my $test ([[0],[]],
                [[],[0]],
                [[0],[1]],
                [[0]],
                [[0,1],[]],
                [[0],[1],[2]],
                [[],[1],[2]],
                [[],[1],[]],
                [[0,1],[2,3],[4,5]],
               ) {
    my $sname = join "; ", map "[@$_]", @$test;
    subtest $sname => sub {
      my @in;
      for my $elt (@$test) {
        push @in, Mock::TokenQueue->new($elt);
      }

      {
        my $full_out = Mock::TokenQueue->new([10..14]);
        Handler::merge(
          Mock::Node->new(),
          { map { ("input$_" => $in[$_]) } 0 .. $#in },
          { out => $full_out });
        my $OK = 1;
        for my $i (0 .. $#in) {
          $OK &&= equal_arrays([$in[$i]->tokens], $test->[$i]);
        }
        ok($OK, "full output: input unchanged");
      }

      my $out = Mock::TokenQueue->new();
      Handler::merge(
        Mock::Node->new(),
        { map { ("input$_" => $in[$_]) } 0 .. $#in },
        { out => $out });

      my $missing_token = test_for_one_queue_short_by_1($test, \@in);
      cmp_deeply([$out->tokens], [$missing_token], "missing token is in the output");
    };
  }

  # TODO: what about when all inputs are empty?
};

# Todo: multiply is not actually a binop, it is a multiop, and can take multiple inputs
test_binop(\&Handler::multiplier, "multiply", sub { $_[0] * $_[1] });

subtest output => sub {
 TODO: {
    local $TODO = "current implementation requires stdout";
    pass();
  }
};

subtest select => sub {
  for my $bool (0, 1) {
    subtest "boolean $bool value" => sub {
      my @in = (Mock::TokenQueue->new([0]),
                Mock::TokenQueue->new([1]),
               );
      my $control = Mock::TokenQueue->new([$bool]);
      my $out = Mock::TokenQueue->new();
      Handler::select(
        Mock::Node->new(),
        { in_t => $in[1], in_f => $in[0], control => $control },
        { output => $out });
      ok($in[$bool]->is_empty, "selected input is empty");
      ok($in[1-$bool]->is_empty, "unselected input is also empty");
      ok($control->is_empty, "control is empty");
      is($out->size, 1, "one token on output");
      is($out->get_token, $bool, "token value");
    }
  }

  # Todo: test quiet return on full outputs, empty inputs
};

subtest sink => sub {
  for my $test ([[]],
                [[0]],

                [[],[]],
                [[0],[]],
                [[],[0]],
                [[0],[1]],
                [[0,1],[]],

                [[0],[1],[2]],
                [[],[1],[2]],
                [[],[1],[]],
                [[0,1],[2,3],[4,5]],
               ) {
    my $sname = join "; ", map "[@$_]", @$test;
    subtest $sname => sub {
      my %in_queues = map { ("input$_" => Mock::TokenQueue->new($test->[$_]))}
        (0 .. $#$test);
      Handler::sink(Mock::Node->new(),
                    \%in_queues,
                    {});
      for my $in (values %in_queues) {
        cmp_deeply([$in->tokens], [], "input exhausted");
      }
    };
  }
};

subtest split => sub {
  for my $outq (['e'],
                ['e', 'e'],
                ['e', 'f'],
                ['f', 'e'],
                ['f', 'f'],
                ['e', 'e', 'e'],
                ['e', 'f', 'e'],
               ) {
    subtest "[@$outq]" => sub {
      my $n = 0;
      my $all_empty = 1;
      my %out;
      for my $i (@$outq) {
        if ($i eq "e") {        # (e)mpty
          $out{"output$n"} = Mock::TokenQueue->new();
        } elsif ($i eq "f") {   # (f)ull
          $out{"output$n"} = Mock::TokenQueue->new([0,0,0,0,0]);
          $all_empty = 0;
        } else {
          die "'$i'???";
        }
        $n++;
      }

      my $in = Mock::TokenQueue->new([7, 13]);
      Handler::split(Mock::Node->new(),
                     { in => $in }, \%out);
      if ($all_empty) {
        cmp_deeply([ $in->tokens ],
                   [ 13 ],
                   "input queue token removed");
        for my $out (values %out) {
          cmp_deeply([ $out->tokens ], [ 7 ], "output queue got a token");
        }
      } else {
        cmp_deeply([ $in->tokens ],
                   [ 7, 13 ],
                   "input queue token not removed");
      }


    };
  }
};

test_binop(\&Handler::subtracter, "subtract", sub { $_[0] - $_[1] });

done_testing();

################################################################
#

sub test_for_one_queue_short_by_1 {
  my ($before, $after) = @_;

  # Exactly one input should be missing exactly one token
  # If so, return the missing token
  # Otherwise return undef

  my $short1 = 0; # number of queues that were short one token
  my $missing_token; # the token that was missing from the input queue
  for my $in_i (0 .. $#$after) {
    if (equal_arrays([$after->[$in_i]->tokens], $before->[$in_i])) {
      pass("input #$in_i unchanged");
    } elsif (defined ($missing_token = short_by_1([$after->[$in_i]->tokens],
                                                  $before->[$in_i]))) {
      is($short1++, 0, "input queue #$in_i is the only short-by-one queue");
    } else {
      ok(0, "input #$in_i went bad");
    }
  }
  is($short1, 1, "exactly one input queue short by 1");
  isnt($missing_token, undef, "missing token is $missing_token");
  return $missing_token;
}

sub equal_arrays {
  my ($a, $b) = @_;
  return unless @$a == @$b;
  for my $i (0 .. $#$a) {
    return unless $a->[$i] == $b->[$i];
  }
  return 1;
}

# Does $a have the same tokens as $b,
# except that one is missing?
sub short_by_1 {
  my ($a, $b) = @_;
  return unless @$a == @$b - 1;
  return $b->[0] if @$a == 0;
  my $missing;
  my $skip = 0;
  for my $i (0 .. $#$a - $skip) {
    next if $a->[$i] == $b->[$i+$skip];
    return if $skip; # already skipped one!
    $skip++;
    $missing = $b->[$i];
    redo;  # check $a->[$i] against $b->[$i+1]
  }
  return $skip && $missing;
}
