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
    $GFD_publication->get_GenomicFeatureDisease()->dbID(),
    $GFD_publication->get_Publication()->dbID()
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_publication', 'GFD_publication_id');
  $GFD_publication->{GFD_publication_id} = $dbID;
  $GFD_publication->{registry} = $self->{registry};
  return $GFD_publication;
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_publication_id = shift;
  my $constraint = "WHERE GFD_publication_id=$GFD_publication_id"; 
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

sub _fetch {
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
  return $gfd_publications[0];
}


1;

