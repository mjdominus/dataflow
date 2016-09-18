package Scheduler::Test;
use DDP;

sub new { shift;
          bless { name => "Dummy Scheduler", %{$_[0]} } => __PACKAGE__;
        }
sub schedule { }
sub system { $_[0]{system} }

1;
