use strict;
use warnings;

package G2P::DBSQL::UserAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::User;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/user_id username email/;

sub fetch_by_email {
  my $self = shift;
  my $email = shift;
  my $constraint = "WHERE email='$email'";
  return $self->_fetch($constraint); 
}

sub fetch_by_username {
  my $self = shift;
  my $name = shift;
  my $constraint = "WHERE username='$name'";
  return $self->_fetch($constraint); 
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @users = ();
  my $query = 'SELECT user_id, username, email FROM user';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %user;
    @user{@columns} = @$row;
    $user{registry} = $self->{registry};
    push @users, G2P::User->new(\%user);  
  }
  $sth->finish();
  return $users[0];    
}

1;
