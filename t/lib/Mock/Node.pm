package Mock::Node;
use Carp qw(confess croak);

sub new {
  my ($class) = @_;
  bless {} => $class;
}

sub notify { $_[0]{notifications}++ }

1;

