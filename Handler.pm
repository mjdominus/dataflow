package Handler;
use base Exporter;

our %EXPORT_TAGS = (all => [qw(adder
                               make_constant
                               make_input make_output)],
                   );
Exporter::export_tags('all');

sub make_constant {
  my ($c) = @_;
  sub {
    my ($self, undef, $o) = @_;
    for my $out (values %$o) {
      unless ($out->is_full) {
        $self->announce("emitting constant $c");
        $out->put_token($c);
        $self->notify unless $out->is_full;
      }
    };
  }
}

################################################################
#
# Arithmetic
#

sub adder {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  # Maybe separate the activation predicate
  # from the hander computation?
  return if $out->is_full;
  for my $in (values %$i) {
    return if $in->is_empty;
  }

  my $s = 0;
  for my $in (values %$i) {
    $s += $in->get_token;
  }
  $self->announce("result=$s");
  $out->put_token($s);
}

sub subtracter {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  return if $i->{arg1}->is_empty;
  return if $i->{arg2}->is_empty;
  return if $out->is_full;

  my $s0 = $i->{arg1}->get_token;
  my $s1 = $i->{arg2}->get_token;
  my $d = $s0 - $s1;

  $self->announce("result=$d");
  $out->put_token($d);
}

# redo this to take arbitrary number of inputs
# like the adder
sub multiplier {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  return if $i->{factor0}->is_empty;
  return if $i->{factor1}->is_empty;
  return if $out->is_full;

  my $prod = $i->{input0}->get_token * $i->{input1}->get_token;

  $self->announce("multiplying; result=$prod");
  $out->put_token($prod);
}

sub divider {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  return if $i->{dividend}->is_empty;
  return if $i->{divisor}->is_empty;
  return if $out->is_full;

  my $s0 = $i->{dividend}->get_token;
  my $s1 = $i->{divisor}->get_token;
  die "Division by zero\n" if $s1 == 0;
  my $q = $s0 / $s1;

  $self->announce("result=$q");
  $out->put_token($q);
}

# Need a way to name these queues
#   input:  dividend, divisor
#   output: quotient, remainder

sub divquot {
  my ($self, $i, $o) = @_;

  return if $i->{dividend}->is_empty;
  return if $i->{divisor}->is_empty;
  return if $o->{quotient}->is_full;
  return if $o->{remainder}->is_full;

  my $dividend = $i->{dividend}->get_token;
  my $divisor  = $i->{divisor}->get_token;
  die "Division by zero\n" if $divisor == 0;
  my $q = int($s0 / $s1);
  my $r = $dividend - $q * $divisor;

  $self->announce("result= quotient $q remainder $r");
  $out->{quotient}->put_token($q);
  $out->{remainder}->put_token($r);
}

################################################################
#
# I/O
#

sub make_input {
  my ($prompt) = @_;
  sub {
    my ($self, undef, $o) = @_;
    my ($out) = values %$o;
    return if $out->is_full;
    print "$prompt> ";
    chomp(my $input = <STDIN>);
    return if $input eq "none" || $input eq "";
    $out->put_token($input);
    $self->notify unless $out->is_full;
  }
}

sub make_output {
  my ($label) = @_;
  sub {
    my (undef, $i, undef) = @_;
    my ($in) = values %$i;
    return if $in->is_empty;
    my $tok = $in->get_token();
    print "*** $label: $tok\n";
  };
}

################################################################
#
# Control
#

sub select {
  die "unimplemented";
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  return if $out->is_full;
}

1;
