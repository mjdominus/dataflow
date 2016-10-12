package PortNames;
use Moo;
use namespace::clean;
use List::Util qw(first);

sub none { return }

*many_out = some("output");
*many_in = some("input");

*one_out = list("output");
*one_in = list("input0");
*two_in = list("input0", "input1");

*select_in = list("control", "in_t", "in_f");

*distribute_in = list("control", "input");
*distribute_out = list("out_t", "out_f");

sub some {
  my ($prefix) = @_;
  return sub {
    my @used;
    for my $name (@_) {
      if ($name =~ /\A \Q$prefix\E (\d+) /x) {
        $used[$1] = 1;
      }
    }
    my $unused = first { ! $used[$_] } 0 .. 0+@used;
    return "$prefix$unused";
  };
}

sub list {
  my @item = @_;
  return sub {
    my %seen = map { $_ => 1 } @_;
    return first { ! $seen{$_} } @item;
  };
}

1;
