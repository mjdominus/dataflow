#!/usr/bin/perl

use Test::More;
use Test::Deep qw(!reftype); # Incompatible with Scalar::Util::reftype
use Test::Fatal;
use LibraryLoader;
use Scalar::Util qw(reftype);

subtest para_to_spec => sub {
  my $ll = LibraryLoader->new();

  like(exception { $ll->para_to_spec({}) }, qr/paragraph missing/i, "missing name");
  like(exception { $ll->para_to_spec({name => "x"}) }, qr/paragraph missing/i, "missing nin");
  like(exception { $ll->para_to_spec({name => "x", nin => "y"}) }, qr/paragraph missing/i,
       "missing non");


  my %p = qw(name name nin  nin non non);

  cmp_deeply($ll->para_to_spec({%p}),
             { name => "name",
               nin => "PortNames::nin",
               non => "PortNames::non",
               autoschedule => 0,
               reqs_args => 0,
               handler => "Handler::name",
             },
             "simplest paragraph");

  cmp_deeply($ll->para_to_spec({%p, reqs_args => 1}),
             { name => "name",
               nin => "PortNames::nin",
               non => "PortNames::non",
               autoschedule => 0,
               reqs_args => 1,
               handler => "Handler::make_name",
             },
             "requires args");

  cmp_deeply($ll->para_to_spec({%p, nin => "A::B", non => "C" }),
             { name => "name",
               nin => "A::B",
               non => "PortNames::C",
               autoschedule => 0,
               reqs_args => 0,
               handler => "Handler::name",
             },
             "nin/non qualification");

  cmp_deeply($ll->para_to_spec({%p, handler => "E::F"}),
             { name => "name",
               nin => "PortNames::nin",
               non => "PortNames::non",
               autoschedule => 0,
               reqs_args => 0,
               handler => "E::F",
             },
             "handler qualification");
};

subtest next_primitive_spec => sub {
  my $ok_spec = "name: this\nnin: that\nnon: other";

  for my $input ("$ok_spec\n",
                 "$ok_spec\n# separate comment\n",
                 "$ok_spec    # trailing comment\n",
                 "#separat comment \n$ok_spec   \n",
                 "name: this\n# inter comment \nnin: that\nnon: other\n",
                 "$ok_spec\n      # comment with leading space\n",
                 "# block comment\n# precedes spec\n\n$ok_spec\n",
                ) {
    open my($ifh), "<", \$input or die;
    my $ll = LibraryLoader->new({ fh => $ifh }) or die;
    my $spec = $ll->next_primitive_spec;
    cmp_deeply($spec, superhashof({ name => "this",
                                    nin => "PortNames::that",
                                    non => "PortNames::other",
                                  }));
  }
};

# see if we can load the default primitive .lib file without error
subtest "check default primitives" => sub {
  my $ll = LibraryLoader->new();
  ok( !(exception { $ll->load_file("library.lib") }),
      "opened library.lib" );
  while (my $spec = $ll->next_primitive_spec) {
    is(reftype($spec), "HASH", "next spec: $spec->{name}");
  }
};


done_testing();
