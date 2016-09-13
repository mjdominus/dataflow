package Util;
use Scalar::Util qw(blessed);
use base Exporter;
our @EXPORT = qw(is_a);
our @EXPORT_OK = qw(attach);

sub is_a {
  my ($x, $class) = @_;
  return defined($x) && ref($x) && $x->isa($class);
}

1;
