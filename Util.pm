package Util;
use base Exporter;
our @EXPORT = qw(is_a);

sub is_a {
  my ($x, $class) = @_;
  return ref($x) && $x->isa($class);
}

1;
