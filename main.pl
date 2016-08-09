#!/usr/bin/perl

use System;

@ARGV or die "Usage: $0 file.df\n";
my ($input) = @ARGV;
@ARGV = ();

my $system = System->new->load_file($input)->run;

1;


