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
  return $self->_fetch_all('');
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

sub fetch_by_synonym {
  my $self = shift;
  my $name = shift;
  my $query = "SELECT genomic_feature_id FROM genomic_feature_synonym WHERE name='$name' LIMIT 1";
  my $genomic_feature_id;
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query, {mysql_use_result => 1});
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  $sth->bind_columns(\($genomic_feature_id));
  $sth->fetch;
  $sth->finish();
  return undef unless (defined($genomic_feature_id));
  return $self->fetch_by_dbID($genomic_feature_id);
}

sub fetch_all_by_substring {
  my $self = shift;
  my $substring = shift;
  my $constraint = "WHERE gene_symbol LIKE '%$substring%' LIMIT 20"; 
  return $self->_fetch_all($constraint);
}

sub _fetch_synonyms {
  my $self = shift;
  my $genomic_feature_id = shift;
  my $query = "SELECT name FROM genomic_feature_synonym WHERE genomic_feature_id=$genomic_feature_id;";
  my @synonyms = ();
  my $name;
  my $dbh = $self->{registry}->new_dbh;
  my $sth = $dbh->prepare($query, {mysql_use_result => 1});
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  $sth->bind_columns(\($name));
  while ($sth->fetch) {
    push @synonyms, $name;
  }
  $sth->finish();
  return \@synonyms;
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
    $genomic_feature{synonyms} = $self->_fetch_synonyms($genomic_feature{genomic_feature_id});
    push @genomic_features, G2P::GenomicFeature->new(\%genomic_feature);
  }
  $sth->finish();
  return $genomic_features[0];
}

sub _fetch_all {
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
    $genomic_feature{synonyms} = $self->_fetch_synonyms($genomic_feature{dbID});
    push @genomic_features, G2P::GenomicFeature->new(\%genomic_feature);
  }
  $sth->finish();
  return \@genomic_features;
}


1;
