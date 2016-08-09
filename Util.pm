package Util;
use Scalar::Util qw(blessed);
use base Exporter;
our @EXPORT = qw(is_a);
our @EXPORT_OK = qw(attach);

sub is_a {
  my ($x, $class) = @_;
  return ref($x) && $x->isa($class);
}

sub attach {
  my ($s, $t) = @_;
  my ($source, $output_name) = blessed($s) ? $s : @$s;
  my ($target, $input_name)  = blessed($t) ? $t : @$t;
  my $tq = TokenQueue->new({ source => $source, target => $target });
  $source->attach_output($output_name, $tq);
  $target->attach_input($input_name, $tq);
}


1;
