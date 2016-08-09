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
        $self->notify;
      }
    };
  }
}

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

sub make_input {
  my ($prompt) = @_;
  sub {
    my ($self, undef, $o) = @_;
    my ($out) = values %$o;
    return if $out->is_full;
    print "$prompt> ";
    chomp(my $input = <>);
    return if $input eq "none" || $input eq "";
    $out->put_token($input);
#    $self->notify;
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
