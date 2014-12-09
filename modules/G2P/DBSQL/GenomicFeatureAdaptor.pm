use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeature;
our @ISA = ('G2P::DBSQL::BaseAdaptor');


my @columns = qw/genomic_feature_id gene_symbol mim ensembl_stable_id seq_region_id seq_region_start seq_region_end seq_region_strand/;

sub store {
  my $self = shift;
  my $gf = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature (
      gene_symbol,
      mim,
      ensembl_stable_id,
      seq_region_id,
      seq_region_start,
      seq_region_end,
      seq_region_strand
    ) VALUES (?,?,?,?,?,?,?)
  });
  $sth->execute(
    $gf->gene_symbol,
    $gf->mim,
    $gf->ensembl_stable_id,
    $gf->{seq_region_id} || undef,
    $gf->{seq_region_start} || undef,
    $gf->{seq_region_end} || undef,
    $gf->{seq_region_strand} || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature', 'genomic_feature_id');
  $gf->{genomic_feature_id} = $dbID;
  $gf->{registry} = $self->{registry};
  return $gf;
}

sub update {
  my $self = shift;
  my $gf = shift;
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature
      SET gene_symbol = ?,
          mim = ?,
          ensembl_stable_id = ?,
          seq_region_id = ?,
          seq_region_start = ?,
          seq_region_end = ?,
          seq_region_strand = ?
      WHERE genomic_feature_id  = ?
  });

  $sth->execute(
    $gf->gene_symbol,
    $gf->mim,
    $gf->ensembl_stable_id,
    $gf->{seq_region_id} || undef,
    $gf->{seq_region_start} || undef,
    $gf->{seq_region_end} || undef,
    $gf->{seq_region_strand} || undef,
    $gf->{genomic_feature_id}
  );

  $sth->finish();
  return $gf;
}

sub fetch_all {
  my $self = shift;
  return $self->_fetch_all();
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_id = shift;
  my $constraint = "WHERE genomic_feature_id=$genomic_feature_id"; 
  return $self->_fetch($constraint);
}

sub fetch_by_mim {
  my $self = shift;
  my $mim = shift;
  my $constraint = "WHERE mim=$mim"; 
  return $self->_fetch($constraint);
}

sub fetch_by_gene_symbol {
  my $self = shift;
  my $gene_symbol = shift;
  my $constraint = "WHERE gene_symbol='$gene_symbol'"; 
  return $self->_fetch($constraint);
}

sub fetch_by_ensembl_stable_id {
  my $self = shift;
  my $ensembl_stable_id = shift;
  my $constraint = "WHERE ensembl_stable_id='$ensembl_stable_id'"; 
  return $self->_fetch($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @genomic_features = ();
  my $query = 'SELECT genomic_feature_id, gene_symbol, mim, ensembl_stable_id FROM genomic_feature';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query, {mysql_use_result => 1});
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %genomic_feature;
    @genomic_feature{@columns} = @$row;
    $genomic_feature{registry} = $self->{registry};
    push @genomic_features, G2P::GenomicFeature->new(\%genomic_feature);
  }
  $sth->finish();
  return $genomic_features[0];
}

sub _fetch_all {
  my $self = shift;
  my $query = 'SELECT genomic_feature_id, gene_symbol, mim, ensembl_stable_id FROM genomic_feature;';
}


1;
