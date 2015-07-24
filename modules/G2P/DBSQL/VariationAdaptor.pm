use strict;
use warnings;

package G2P::DBSQL::VariationAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::Variation;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/variation_id genomic_feature_id disease_id publication_id mutation consequence/;

sub store {
  my $self = shift;
  my $variation = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO variation (
      genomic_feature_id,
      disease_id,
      publication_id,
      mutation,
      consequence
    ) VALUES (?,?,?,?,?)
  });
  $sth->execute(
    $variation->genomic_feature_id,
    $variation->disease_id,
    $variation->publication_id || undef,
    $variation->mutation || undef,
    $variation->consequence || undef
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'variation', 'variation_id');
  $variation->{variation_id} = $dbID;
  $variation->{registry} = $self->{registry};

  # insert synonyms
  $sth = $dbh->prepare(q{
    INSERT INTO variation_synonym (
      variation_id,
      name,
      source
    ) VALUES (?,?,?)
  });

  my $synonyms = $variation->{synonyms};
  foreach my $source (keys %$synonyms) {
    foreach my $name (keys %{$synonyms->{$source}}) {
      $sth->execute(
        $dbID,
        $name,
        $source
      );
    }  
  } 
  $sth->finish();
  return $variation;
}


# disease_name -> genomic_feature -> variation
sub fetch_all_by_genomic_feature_id_disease_id {
  my $self = shift;
  my $genomic_feature_id = shift;
  my $disease_id = shift;
  my $constraint = " WHERE genomic_feature_id=$genomic_feature_id AND disease_id=$disease_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all_by_Disease_order_by_genomic_feature_id {
  my $self = shift;
  my $disease = shift;
  my $disease_id = $disease->dbID;
  my $constraint = " WHERE disease_id=$disease_id";
  my $variations = $self->_fetch_all($constraint);
  my $genomic_features = {};
  foreach my $variation (@$variations) {
    my $genomic_feature_id = $variation->genomic_feature_id;
    push @{$genomic_features->{$genomic_feature_id}}, $variation;
  }
  return $genomic_features;
}

sub fetch_all_by_GenomicFeature_order_by_disease_id {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = " WHERE genomic_feature_id=$genomic_feature_id";
  my $variations = $self->_fetch_all($constraint);
  my $diseases = {};
  foreach my $variation (@$variations) {
    my $disease_id = $variation->disease_id;
    push @{$diseases->{$disease_id}}, $variation;
  }
  return $diseases;
}

sub fetch_all_synonyms_order_by_source_by_variation_id {
  my $self = shift;
  my $variation_id = shift;
  my $variation_synonyms = {};
  my $query = "SELECT name, source FROM variation_synonym WHERE variation_id=$variation_id";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my $name = $row->[0];
    my $source = $row->[1];
    push @{$variation_synonyms->{$source}}, $name;
  }
  return $variation_synonyms;
}

sub fetch_all_by_genomic_feature_id {
  my $self = shift;
  my $genomic_feature_id = shift;
  my $constraint = "WHERE genomic_feature_id=$genomic_feature_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all_by_disease_id {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = "WHERE disease_id=$disease_id";
  return $self->_fetch_all($constraint);
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @variations = ();
  my $query = 'SELECT variation_id, genomic_feature_id, disease_id, publication_id, mutation, consequence FROM variation';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %variation;
    @variation{@columns} = @$row;
    $variation{registry} = $self->{registry};
    push @variations, G2P::Variation->new(\%variation);
  }
  return \@variations;
}

1;
