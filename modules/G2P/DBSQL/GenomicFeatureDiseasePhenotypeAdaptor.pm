use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseasePhenotypeAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDiseasePhenotype;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/GFD_phenotype_id genomic_feature_disease_id phenotype_id/;

sub store {
  my $self = shift;
  my $GFD_phenotype = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_phenotype (
      genomic_feature_disease_id,
      phenotype_id
    ) VALUES (?,?);
  });
  $sth->execute(
    $GFD_phenotype->get_GenomicFeatureDisease()->dbID(),
    $GFD_phenotype->get_Phenotype()->dbID()
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_phenotype', 'GFD_phenotype_id');
  $GFD_phenotype->{GFD_phenotype_id} = $dbID;
  $GFD_phenotype->{registry} = $self->{registry};
  return $GFD_phenotype;
}

sub delete {
  my $self = shift;
  my $GFDP = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFDP) || !$GFDP->isa('G2P::GenomicFeatureDiseasePhenotype')) {
    die ('G2P::GenomicFeatureDiseasePhenotype arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_phenotype WHERE GFD_phenotype_id = ?;
  });
  
  $sth->execute($GFDP->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_phenotype_id = shift;
  my $constraint = "WHERE GFD_phenotype_id=$GFD_phenotype_id"; 
  return $self->_fetch($constraint);
}

sub fetch_by_GFD_id_phenotype_id {
  my $self = shift;
  my $GFD_id = shift;
  my $phenotype_id = shift;
  my $constraint = "WHERE genomic_feature_disease_id=$GFD_id AND phenotype_id=$phenotype_id";
  return $self->_fetch($constraint);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $GFD = shift;
  if (!ref($GFD) || !$GFD->isa('G2P::GenomicFeatureDisease')) {
    die('G2P::GenomicFeatureDisease arg expected');
  }
  my $GFD_id = $GFD->dbID;
  my $constraint = "WHERE genomic_feature_disease_id=$GFD_id"; 
  return $self->_fetch_all($constraint);
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @gfd_phenotypes = ();
  my $query = 'SELECT GFD_phenotype_id, genomic_feature_disease_id, phenotype_id FROM genomic_feature_disease_phenotype';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_phenotype;
    @gfd_phenotype{@columns} = @$row;
    $gfd_phenotype{registry} = $self->{registry};
    push @gfd_phenotypes, G2P::GenomicFeatureDiseasePhenotype->new(\%gfd_phenotype);
  }
  return \@gfd_phenotypes;
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @gfd_phenotypes = ();
  my $query = 'SELECT GFD_phenotype_id, genomic_feature_disease_id, phenotype_id FROM genomic_feature_disease_phenotype';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_phenotype;
    @gfd_phenotype{@columns} = @$row;
    $gfd_phenotype{registry} = $self->{registry};
    push @gfd_phenotypes, G2P::GenomicFeatureDiseasePhenotype->new(\%gfd_phenotype);
  }
  return $gfd_phenotypes[0];
}


1;

