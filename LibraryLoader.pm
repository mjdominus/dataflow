package LibraryLoader;
# loads .lib specifications or primitive components
use Moo;
use namespace::clean;

has handler_class => (
  is => 'ro',
  default => sub { "Handler" },
);

has fh => (
  is => 'rwp',
  predicate => 'fh_open',
);

sub _read_para {
  my ($self) = @_;
  my $fh = $self->fh;
  my $BAD = 0;
  while (1) {
    my $para = do {
      local $/ = "";            # paragraph mode
      scalar <$fh>;
    };
    return unless defined $para; # EOF
    $para =~ s/\# .* $//mgx;      # discards all comments
    $para =~ s/ \s+ $//mgx;       # discards each line's trailing whitespace
    if ($para =~ /\S/) {          # nonempty paragraph
      chomp(my @lines = grep /\S/, split /^/, $para);
      my %h;
      for my $l (@lines) {
        my ($k, $v) = ($l =~ /\A ([^:]+) : \s* (.*) \z/x)
          or do {
            $BAD++;
            warn "Malformed line <$l>\n";
          };
        if (exists $h{$k}) { $BAD++; warn "Duplicate spec for key '$k'\n" }
        else { $h{$k} = $v }
      }
      die "Bad paragraph $. in primitive node spec file" if $BAD;
      return \%h;
    }
    # otherwise go back and try the next one
  }
}

sub load_file {
  my ($self, $file) = @_;
  open my($fh), "<", $file
    or die "Couldn't open file '$file': $!";
  $self->_set_fh($fh);
  return 1;
}

sub next_primitive_spec {
  my ($self) = @_;
  die "No file specified for loading" unless $self->fh_open;
  my $para = $self->_read_para;
  return defined $para ? $self->para_to_spec($para) : ();
}

sub para_to_spec {
  my ($self, $para) = @_;

  # check for required items
  for my $req (qw / name nin non / ) {
    die "Paragraph missing required '$req' item\n" # fix: better message for this later
      unless $para->{$req};
  }

  # now fill in missing defaults from spec
  $para->{reqs_args}    //= 0;
  $para->{autoschedule} //= 0;

  $para->{handler} //= $para->{reqs_args} ? "make_$para->{name}" : $para->{name};
  $self->_qualify($para, 'handler', $self->handler_class);

  return $para;
}

# Maybe you can get rid of this for handler functions like you did for
# portname functions.
sub _qualify {
  my ($self, $spec, $key, $def_package) = @_;
  return if $spec->{$key} =~ /::/; # already qualified
  $spec->{$key} = join "::", $def_package, $spec->{$key};
}

1;
