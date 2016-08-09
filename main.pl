#!/usr/bin/perl

use System;
use Compiler;

@ARGV or die "Usage: $0 file.df\n";
my ($input) = @ARGV;
@ARGV = ();

Compiler->new->load_file($input)->run;

1;


