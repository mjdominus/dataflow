#!/usr/bin/perl

use System;
use Compiler;
use Getopt::Std;

# sub DB::sub { print ">> $DB::sub @_\n" if $DB::sub =~ /Network|Port|Interface|System|Library|Component/; goto &$DB::sub }

my %opt = (s => 'Queue',  # default scheduler is Queue
           d => '',       # no debugging
    );

getopts('d:s:', \%opt) or usage();

@ARGV == 1 or die "Usage: $0 [-s scheduler-type] file.df\n";
my ($input) = @ARGV;

my $system = System->new({ scheduler_factory => $opt{s} });
   $system->initialize_network($input);

1;

for my $component (split /,\s*/, $opt{d}) {
  if    ($component eq "SYSTEM")    { $system                       ->debug(1) }
  elsif ($component eq "SCHEDULER") { $system->scheduler            ->debug(1) }
  elsif ($component eq "ALL")       { $_->debug(1) for $system->all_components }
  else                              { $system->component($component)->debug(1) }
}

$system->scheduler->announce_state;
$system->run;

print STDERR "Shutting down.\n";


