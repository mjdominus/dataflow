#!/usr/bin/perl

use System;
use Component;
use Handlers ':all';
use TokenQueue;

my $system = System->new;

my ($in, $three, $add, $out) =
  (Component->new({ name => "in",    handler => make_input("input"), system => $system }),
   Component->new({ name => "three", handler => make_constant(3),    system => $system }),
   Component->new({ name => "add",   handler => \&adder,             system => $system }),
   Component->new({ name => "out",   handler => make_output("output"), system => $system }),
  );

sub attach {
  my ($source, $output_name, $target, $input_name) = @_;
  my $tq = TokenQueue->new({ source => $source, target => $target });
  $source->attach_output($output_name, $tq);
  $target->attach_input($input_name, $tq);
}

attach($in,    undef, $add, undef);
attach($three, undef, $add, undef);
attach($add,   undef, $out, undef);

$system->schedule($in, $three);
$system->run;

1;


