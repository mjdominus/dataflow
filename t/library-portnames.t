#!/usr/bin/perl

use Test::More;
use PortNames;
use t::lib::TestUtil;
use Try::Tiny;
use Test::Fatal;

is(exception { PortNames::none() }, undef, "PortNames::none");
my %seen = ("none" => 1);

open my($fh), "<", "library.lib" or die "Couldn't open library.lib: $!";
while (<$fh>) {
  next unless /\A n[io]n : \s* (.*) /x;
  my $f = $1;
  next if $seen{$f}++;
  my $r;
  try { $r = PortNames->namespace($f) };
  isnt($r, undef, "$f");
}

done_testing();
