#!/usr/bin/perl

use Test::More;
my @modules = qw| Compiler
                  Component::Compound Component::Primitive
                  Handler Interface
                  LibraryLoader Library
                  Namespace::NameList Namespace::NamePrefix
                  Network Node PortNames
                  Scheduler::Queue System TokenQueue Util
                |;

for my $module (@modules) {
  my $file = $module =~ s|::|/|gr;
  $file = "$file.pm";
  ok(eval { require $file }, $module);
}

done_testing();
