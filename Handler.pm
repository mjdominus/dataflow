package Handler;

sub handler_list {
  qw[ make_constant
      adder subtracter multiplier divider
      make_input make_output
   ];
}

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

  return if $i->{input0}->is_empty;
  return if $i->{input1}->is_empty;
  return if $out->is_full;

  my $s0 = $i->{input0}->get_token;
  my $s1 = $i->{input1}->get_token;
  my $d = $s0 - $s1;

  $self->announce("result=$d");
  $out->put_token($d);
}

sub multiplier {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  return if $i->{input0}->is_empty;
  return if $i->{input1}->is_empty;
  return if $out->is_full;

  my $prod = $i->{input0}->get_token * $i->{input1}->get_token;

  $self->announce("multiplying; result=$prod");
  $out->put_token($prod);
}

sub divider {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;

  return if $i->{input0}->is_empty;
  return if $i->{input1}->is_empty;
  return if $out->is_full;

  my $s0 = $i->{input0}->get_token;
  my $s1 = $i->{input1}->get_token;
  die "Division by zero\n" if $s1 == 0;
  my $q = $s0 / $s1;

  $self->announce("result=$q");
  $out->put_token($q);
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
    $out->put_token($input) unless $input eq "pass";   # reschedule but don't generate a token
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

1;
