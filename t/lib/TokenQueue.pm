
package TokenQueue;
use Carp qw(confess croak);

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

sub source {}
sub target {}

1;
