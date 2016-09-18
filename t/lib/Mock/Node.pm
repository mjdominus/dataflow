package Mock::Node;
use Carp qw(confess croak);

sub new {
  my ($class, $name) = @_;
  $name //= "mocknode" . ++$counter;
  bless { name => $name, notifications => 0 } => $class;
}

sub notify { $_[0]{notifications}++ }
sub name { $_[0]{name} }
sub announce {}

1;

