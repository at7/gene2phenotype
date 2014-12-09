use strict;
use warnings;

package G2P::User;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;

  my $self = bless {
    user_id => $params->{user_id},
    username => $params->{username},
    email => $params->{email},
  }, $class;
  return $self;
}

sub user_id {
  my $self = shift;
  return $self->{user_id};
}

sub username {
  my $self = shift;
  return $self->{username};
}

sub email {
  my $self = shift;
  return $self->{email};
}

1;
