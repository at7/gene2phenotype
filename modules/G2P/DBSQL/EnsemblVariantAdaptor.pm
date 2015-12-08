use strict;
use warnings;

package G2P::DBSQL::EnsemblVariantAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::EnsemblVariant;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/variant_id genomic_feature_id seq_region seq_region_start seq_region_end seq_region_strand name source allele_string consequence feature_stable_id amino_acid_string polyphen_prediction sift_prediction/;

sub store {
  my $self = shift;
  my $variant = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO ensembl_variant (
      genomic_feature_id,
      seq_region,
      seq_region_start,
      seq_region_end,
      seq_region_strand,
      name,
      source,
      allele_string,
      consequence,
      feature_stable_id,
      amino_acid_string,
      polyphen_prediction,
      sift_prediction
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
  });
  $sth->execute(
    $variant->genomic_feature_id,
    $variant->seq_region,
    $variant->seq_region_start,
    $variant->seq_region_end,
    $variant->seq_region_strand,
    $variant->name,
    $variant->source,
    $variant->allele_string,
    $variant->consequence,
    $variant->feature_stable_id,
    $variant->amino_acid_string || undef,
    $variant->polyphen_prediction || undef,
    $variant->sift_prediction || undef,  
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'ensembl_variant', 'variant_id');
  $variant->{variant_id} = $dbID;
  $variant->{registry} = $self->{registry};

  return $variant;
}

sub fetch_all_by_GenomicFeature {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = " WHERE genomic_feature_id=$genomic_feature_id";
  return $self->_fetch_all($constraint);
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @variations = ();
  my $query = 'SELECT variant_id, genomic_feature_id, seq_region, seq_region_start, seq_region_end, seq_region_strand, name, source, allele_string, consequence, feature_stable_id, amino_acid_string, polyphen_prediction, sift_prediction FROM ensembl_variant';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %variation;
    @variation{@columns} = @$row;
    $variation{registry} = $self->{registry};
    push @variations, G2P::EnsemblVariant->new(\%variation);
  }
  return \@variations;
}

1;
