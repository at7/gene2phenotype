use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDiseasePublication;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/GFD_publication_id genomic_feature_disease_id publication_id/;

sub store {
  my $self = shift;
  my $GFD_publication = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_publication (
      genomic_feature_disease_id,
      publication_id
    ) VALUES (?,?);
  });
  $sth->execute(
    $GFD_publication->genomic_feature_disease()->dbID(),
    $GFD_publication->publication()->dbID()
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_publication', 'GFD_publication_id');
  $gf->{GFD_publication_id} = $dbID;
  $gf->{registry} = $self->{registry};
  return $gf;
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
  my @gfd_publications = ();
  my $query = 'SELECT GFD_publication_id, genomic_feature_disease_id, publication_id FROM genomic_feature_disease_publication';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_publication;
    @gfd_publication{@columns} = @$row;
    $gfd_publication{registry} = $self->{registry};
    push @gfd_publications, G2P::GenomicFeatureDiseasePublication->new(\%gfd_publication);
  }
  return \@gfd_publications;
}


1;

