#!/usr/bin/perl

use Test::More;
my @modules = qw| Compiler Component Handler Interface
                  Library Network Node Scheduler/Queue
                  System TokenQueue Util
                |;

for my $module (@modules) {
  my $file = "$module.pm";
  ok(eval { require $file }, $module);
}

done_testing();
