use strict;
use warnings;

package G2P::DBSQL::OrganSpecificityAdaptor;

use G2P::DBSQL::BaseAdaptor;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

sub fetch_list_by_GenomicFeature {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  return $self->fetch_list($genomic_feature_id);
}

sub fetch_list {
  my $self = shift;
  my $genomic_feature_id = shift;
  my @organs = ();
  my $query = "SELECT os.organ_specificity FROM organ_specificity os, genomic_feature_organ_specificity gfos WHERE os.organ_specificity_id = gfos.organ_specificity_id AND gfos.genomic_feature_id=$genomic_feature_id;";

  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    push @organs, $row->[0];
  }
  $sth->finish();
  my @sorted_organ_list = sort @organs;
  return \@sorted_organ_list;
}

1;
