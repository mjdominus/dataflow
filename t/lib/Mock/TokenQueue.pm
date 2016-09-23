
package Mock::TokenQueue;
use Carp qw(confess croak);
use Mock::Node;

my $fake_node = Mock::Node->new();

# $tokens is an initial queue of tokens
sub new {
  my ($class, $tokens) = @_;
  $tokens //= [];
  bless [@$tokens] => $class;
}

sub name { "tokenqueue" }

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

sub tokens { @{$_[0]} }

sub is_empty { @{$_[0]} == 0 }
sub is_full { @{$_[0]} == 5 }

sub size { 0 + @{$_[0]} }

sub source { $fake_node }
sub target { $fake_node }

1;
