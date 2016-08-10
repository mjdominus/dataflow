#!/usr/bin/perl

use System;
use Compiler;
use Getopt::Std;

my %opt = (s => 'Queue',  # default scheduler is Queue
           d => '',       # no debugging
    );

getopts('d:s:', \%opt) or usage();

@ARGV == 1 or die "Usage: $0 [-s scheduler-type] file.df\n";
my ($input) = @ARGV;

my $system = System->new({ scheduler_factory => $opt{s} })->load_file($input);

for my $component (split /,\s*/, $opt{d}) {
  if    ($component eq "system")    { $system                       ->debug(1) }
  elsif ($component eq "scheduler") { $system->scheduler            ->debug(1) }
  else                              { $system->component($component)->debug(1) }
}

$system->scheduler->announce_state;
$system->run;


