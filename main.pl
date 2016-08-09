#!/usr/bin/perl

use System;
use Component;
use TokenQueue;

my $system = System->new;

my ($in, $three, $add, $out) =
  (Component->new({ name => "in",    handler => make_input("input"), system => $system }),
   Component->new({ name => "three", handler => make_constant(3),    system => $system }),
   Component->new({ name => "add",   handler => \&adder,             system => $system }),
   Component->new({ name => "out",   handler => make_output("output"), system => $system }),
  );

sub attach {
  my ($source, $output_name, $target, $input_name) = @_;
  my $tq = TokenQueue->new({ source => $source, target => $target });
  $source->attach_output($output_name, $tq);
  $target->attach_input($input_name, $tq);
}

attach($in,    undef, $add, undef);
attach($three, undef, $add, undef);
attach($add,   undef, $out, undef);

$system->schedule($in, $three);
$system->run;

sub make_constant {
  my ($c) = @_;
  sub {
    my ($self, undef, $o) = @_;
    for my $out (values %$o) {
      unless ($out->is_full) {
        print $self->name . ": emmitting constant $c\n";
        $out->queue_token($c);
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
    $s += $in->pop_token;
  }
  print $self->name . ": adding; result=$s\n";
  $out->queue_token($s);
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
    $out->queue_token($input);
#    $self->notify;
  }
}

sub make_output {
  my ($label) = @_;
  sub {
    my (undef, $i, undef) = @_;
    my ($in) = values %$i;
    return if $in->is_empty;
    my $tok = $in->pop_token();
    print "*** $label: $tok\n";
  };
}



1;


