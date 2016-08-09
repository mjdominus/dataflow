#!/usr/bin/perl

use System;
use Component;
use Handlers ':all';
use TokenQueue;
use Util qw(attach);

my $system = System->new;

my ($in, $three, $add, $out) =
  (Component->new({ name => "in",    handler => make_input("input"), system => $system }),
   Component->new({ name => "three", handler => make_constant(3),    system => $system }),
   Component->new({ name => "add",   handler => \&adder,             system => $system }),
   Component->new({ name => "out",   handler => make_output("output"), system => $system }),
  );

attach($in,    $add);
attach($three, $add);
attach($add,   $out);

$system->schedule($in, $three);
$system->run;

1;


