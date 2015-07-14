use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseaseOrganAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDiseaseOrgan;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/GFD_organ_id genomic_feature_disease_id organ_id/;

sub store {
  my $self = shift;
  my $GFD_organ = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_organ (
      genomic_feature_disease_id,
      organ_id
    ) VALUES (?,?);
  });
  $sth->execute(
    $GFD_organ->get_GenomicFeatureDisease()->dbID(),
    $GFD_organ->get_Organ()->dbID()
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_organ', 'GFD_organ_id');
  $GFD_organ->{GFD_organ_id} = $dbID;
  $GFD_organ->{registry} = $self->{registry};
  return $GFD_organ;
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_organ_id = shift;
  my $constraint = "WHERE GFD_organ_id=$GFD_organ_id"; 
  return $self->_fetch($constraint);
}

sub fetch_by_GFD_id_organ_id {
  my $self = shift;
  my $GFD_id = shift;
  my $organ_id = shift;
  my $constraint = "WHERE genomic_feature_disease_id=$GFD_id AND organ_id=$organ_id";
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

sub delete_all_by_GFD_id {
  my $self = shift;
  my $GFD_id = shift;
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare("DELETE FROM genomic_feature_disease_organ WHERE genomic_feature_disease_id=$GFD_id");
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  $sth->finish();
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @gfd_organs = ();
  my $query = 'SELECT GFD_organ_id, genomic_feature_disease_id, organ_id FROM genomic_feature_disease_organ';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_organ;
    @gfd_organ{@columns} = @$row;
    $gfd_organ{registry} = $self->{registry};
    push @gfd_organs, G2P::GenomicFeatureDiseaseOrgan->new(\%gfd_organ);
  }
  return \@gfd_organs;
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @gfd_organs = ();
  my $query = 'SELECT GFD_organ_id, genomic_feature_disease_id, organ_id FROM genomic_feature_disease_organ';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_organ;
    @gfd_organ{@columns} = @$row;
    $gfd_organ{registry} = $self->{registry};
    push @gfd_organs, G2P::GenomicFeatureDiseaseOrgan->new(\%gfd_organ);
  }
  return $gfd_organs[0];
}


1;

