package Mock::Node;
use Carp qw(confess croak);

sub new {
  my ($class) = @_;
  bless {} => $class;
}

1;

