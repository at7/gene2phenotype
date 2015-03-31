use strict;
use warnings;

package G2P::DBSQL::DiseaseAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::Disease;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/disease_id name mim/;

sub store {
  $self = shift;
  my $disease = shift;
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO disease (
      name,
      mim
    ) VALUES (?, ?)
  });

  $sth->execute(
    $disease->name,
    $disease->mim || undef,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id();
  $disease->{disease_id} = $dbID;
  $disease->{registry} = $self->{registry}; 
  return $disease;
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "WHERE name='$name'";
  return $self->_fetch($constraint);
}

sub fetch_by_mim {
  my $self = shift;
  my $mim = shift;
  my $constraint = "WHERE mim=$mim";
  return $self->_fetch($constraint);
}

sub fetch_by_dbID {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = "WHERE disease_id=$disease_id";
  return $self->_fetch($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @diseases = ();
  my $query = 'SELECT disease_id, name, mim FROM disease';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %disease;
    @disease{@columns} = @$row;
    $disease{registry} = $self->{registry};
    push @diseases, G2P::Disease->new(\%disease);
  }
  $sth->finish();
  return $diseases[0];
}

1;
