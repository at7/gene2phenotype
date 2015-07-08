use strict;
use warnings;

package G2P::DBSQL::OrganAdaptor;

use G2P::DBSQL::BaseAdaptor;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/organ_id name/;

sub store {
  my $self = shift;
  my $organ = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO organ (
      name
    ) VALUES (?);
  });
  $sth->execute(
    $organ->name || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'organ', 'organ_id');
  $organ->{organ_id} = $dbID;
  $organ->{registry} = $self->{registry};
  return $organ;
}

sub fetch_by_organ_id {
  my $self = shift;
  my $organ_id = shift;
  $self->fetch_by_dbID($organ_id);
}

sub fetch_by_dbID {
  my $self = shift;
  my $organ_id = shift;
  my $constraint = "WHERE organ_id=$organ_id";
  return $self->_fetch($constraint);
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "WHERE name='$name'";
  return $self->_fetch($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @organs = ();
  my $query = 'SELECT organ_id, name FROM organ';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %organ;
    @organ{@columns} = @$row;
    $organ{registry} = $self->{registry};
    push @organs, G2P::Organ->new(\%organ); 
  }
  return $organs[0];
}

1;
