
package Mock::TokenQueue;
use Carp qw(confess croak);
use Mock::Node;

my $fake_node = Mock::Node->new();

sub new {
  my ($class) = @_;
  bless [] => $class;
}

sub get_token {
  my ($self) = @_;
  confess "empty token queue" if $self->is_empty;
  shift @$self;
}

sub put_token {
  my ($self, $token) = @_;
  confess "full token queue" if $self->is_full;
  push @$self, $token
}

sub is_empty { @{$_[0]} == 0 }
sub is_full { @{$_[0]} == 5 }

sub size { 0 + @{$_[0]} }

sub source { $fake_node }
sub target { $fake_node }

1;
