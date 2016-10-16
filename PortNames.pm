package PortNames;
use Moo;
use Namespace::NameList;
use Namespace::NamePrefix;
use Carp qw(croak);
use namespace::clean;


sub none { return }

my %namespace = (
  many_out => _prefix("output"),
  many_in => _prefix("input"),

  one_out => _list("output"),
  one_in => _list("input0"),
  two_in => _list("input0", "input1"),

  select_in => _list("control", "in_t", "in_f"),

  distribute_in => _list("control", "input"),
  distribute_out => _list("out_t", "out_f"),
);

sub _prefix {
  my ($prefix) = @_;
  Namespace::NamePrefix->new({ prefix => $prefix });
}

sub _list {
  my (@name_list) = @_;
  Namespace::NameList->new({ name_list => \@name_list });
}

sub namespace {
  my ($class, $name) = @_;
  croak "Unknown portname specification '$name'"
    unless exists $namespace{$name};
  return $namespace{$name};
}

1;
