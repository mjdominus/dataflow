#!/usr/bin/perl

use System;
use Component;
use TokenQueue;

my $system = System->new;




$system->load_file("test.df");
$system->run;

1;


