use strict;
use warnings;

package G2P::DBSQL::PhenotypeAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::Phenotype;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/phenotype_id stable_id name description/;

sub store {
  my $self = shift;
  my $phenotype = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO phenotype (
      stable_id,
      name,
      description
    ) VALUES (?,?,?);
  });
  $sth->execute(
    $phenotype->stable_id || undef,
    $phenotype->name || undef,
    $phenotype->description || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'phenotype', 'phenotype_id');
  $phenotype->{phenotype_id} = $dbID;
  $phenotype->{registry} = $self->{registry};
  return $phenotype;
}

sub update {
  my $self = shift;
  my $phenotype = shift;
  my $dbh = $self->{dbh};

  if (!ref($phenotype) || !$phenotype->isa('G2P::Phenotype')) {
    die('G2P::Phenotype arg expected');
  }

  my $sth = $dbh->prepare(q{
    UPDATE phenotype
      SET stable_id = ?,
          name = ?,
          description = ?
      WHERE phenotype_id = ? 
  });
  $sth->execute(
    $phenotype->{stable_id},
    $phenotype->{name},
    $phenotype->{description},
    $phenotype->dbID
  );
  $sth->finish();

  return $phenotype;
}

sub fetch_by_phenotype_id {
  my $self = shift;
  my $phenotype_id = shift;
  $self->fetch_by_dbID($phenotype_id);
}

sub fetch_by_dbID {
  my $self = shift;
  my $phenotype_id = shift;
  my $constraint = "WHERE phenotype_id=$phenotype_id";
  return $self->_fetch($constraint);
}

sub fetch_by_stable_id {
  my $self = shift;
  my $stable_id = shift;
  my $constraint = "WHERE stable_id='$stable_id'";
  return $self->_fetch($constraint);
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "WHERE name='$name'";
  return $self->_fetch($constraint);
}

sub fetch_all {
  my $self = shift;
  return $self->_fetch_all('');
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @phenotypes = ();
  my $query = 'SELECT phenotype_id, stable_id, name, description FROM phenotype';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %phenotype;
    @phenotype{@columns} = @$row;
    $phenotype{registry} = $self->{registry};
    push @phenotypes, G2P::Phenotype->new(\%phenotype); 
  }
  return $phenotypes[0];
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @phenotypes = ();
  my $query = 'SELECT phenotype_id, stable_id, name, description FROM phenotype';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %phenotype;
    @phenotype{@columns} = @$row;
    $phenotype{registry} = $self->{registry};
    push @phenotypes, G2P::Phenotype->new(\%phenotype); 
  }
  return \@phenotypes;
}

1;
