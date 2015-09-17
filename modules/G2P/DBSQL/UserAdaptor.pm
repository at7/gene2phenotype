use strict;
use warnings;

package G2P::DBSQL::UserAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::User;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/user_id username email panel/;

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

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  my $constraint = "WHERE user_id=$dbID";
  return $self->_fetch($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @users = ();
  my $query = 'SELECT user_id, username, email, panel FROM user';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %user;
    @user{@columns} = @$row;
    $user{registry} = $self->{registry};
    if ($user{panel}) {
      my @ids = split(',', $user{panel}) {
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $user{panel} = join(',', @values);      
    }   
    push @users, G2P::User->new(\%user);  
  }
  $sth->finish();
  return $users[0];
}

1;
