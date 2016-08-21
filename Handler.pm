package Handler;

sub handler_list {
  qw[ make_constant
      adder subtracter multiplier divider
      make_input make_output
      merge split sink
      make_comparator
      select distribute
   ];
}

# Emit at most $n tokens with value $c
# If $n not supplied, emit an unlimited number of tokens
sub make_constant {
  my ($c, $n) = @_;
  my $infinity = not defined $n;
  sub {
    my ($self, undef, $o) = @_;
    return unless $infinity || $n > 0;
    for my $out (values %$o) {
      unless ($out->is_full) {
        $self->announce("emitting constant $c");
        $out->put_token($c);
        $self->notify unless $out->is_full;
        return unless $infinity || --$n > 0;
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
# Comparisons
#

sub make_comparator {
  my ($op) = @_;
  my $opf = { ">"  => sub { $_[0] >  $_[1] },
              "="  => sub { $_[0] == $_[1] },
              "<"  => sub { $_[0] <  $_[1] },
              ">=" => sub { $_[0] >= $_[1] },
              "<=" => sub { $_[0] <= $_[1] },
              "!=" => sub { $_[0] != $_[1] },
            };
  my $cmp = $opf->{$op} or die "Unknown comparator op '$op'\n";
  sub {
    my ($self, $i, $o) = @_;
    return if $i->{input0}->is_empty();
    return if $i->{input1}->is_empty();
    return if $o->{output0}->is_full();
    my ($a, $b) = map $i->{$_}->get_token, qw(input0 input1);
    my $res = 0 + $cmp->($a, $b);
    $self->announce(sprintf "comparator %s %s %s yields %s",
                    $a, $op, $b, $res ? "TRUE" : "FALSE");
    $o->{output0}->put_token($res);
  };
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
    return if $input eq "none"; # discard and don't reschedule for more
    unless ($input eq "pass" || $input eq "") {
      $self->announce("queueing token ($input)");
      $out->put_token($input);
    }
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
# Token flow
#

sub merge {
  my ($self, $i, $o) = @_;
  my ($o_name) = keys %$o;
  my $out = $o->{$o_name};
  return if $out->is_full;
  for my $i_name (keys %$i) {
    my $in = $i->{$i_name};
    unless ($in->is_empty) {
      my $token = $in->get_token();
      $self->announce("merging token ($token) from input '$i_name' to output '$o_name'");
      $out->put_token($token);
      $self->notify;
      return;
    }
  }
  $self->announce("nothing to merge");
}

sub split {
  my ($self, $i, $o) = @_;
  my ($i_name) = keys %$i;
  my $in = $i->{$i_name};

  return if $in->is_empty;
  for my $out (values %$o) {
    return if $out->is_full;
  }

  my $token = $in->get_token;
  for my $o_name (keys %$o) {
    my $out = $o->{$o_name};
    unless ($out->is_full) {
      $self->announce("splitting token from input '$i_name' to output '$o_name'");
      $out->put_token($token);
    }
  }
}

sub sink {
  my ($self, $i, $o) = @_;
  for my $in (values %$i) {
    $in->get_token() until $in->is_empty();
  }
}


################################################################
#
# Control flow
#

sub select {
  my ($self, $i, $o) = @_;
  my ($out) = values %$o;
  return if $out->is_full;
  for my $in (values %$i) {
    return if $in->is_empty;
  }

  my $control = $i->{control}->get_token();
  my $t_tok = $i->{in_t}->get_token();
  my $f_tok = $i->{in_f}->get_token();
  $out->put_token($control ? $t_tok : $f_tok);
}

sub distribute {
  my ($self, $i, $o) = @_;

  for my $in (values %$i) {
    return if $in->is_empty;
  }
  for my $out (values %$o) {
    return if $out->is_full;
  }

  my $control = $i->{control}->get_token();
  my $tok = $i->{input}->get_token();

  $o->{$control ? 'output_t' : 'output_f'}->put_token($tok);
}


1;
