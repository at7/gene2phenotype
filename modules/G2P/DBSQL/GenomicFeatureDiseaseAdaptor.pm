use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseaseAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDisease;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/genomic_feature_disease_id genomic_feature_id disease_id DDD_category_attrib/;


sub store {
  my $self = shift;
  my $gfd = shift;
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease(
      genomic_feature_id,
      disease_id,
      DDD_category_attrib
    ) VALUES (?, ?, ?)
  });

  $sth->execute(
    $gfd->{genomic_feature_id},
    $gfd->{disease_id},
    $gfd->DDD_category_attrib || undef,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease', 'genomic_feature_disease_id'); 
  $gfd->{genomic_feature_disease_id} = $dbID;
  $gfd->{registry} = $self->{registry};
  return $gfd;
}

sub update {
  my $self = shift;
  my $gfd = shift;
  my $dbh = $self->{dbh};
  
  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature_disease
      SET genomic_feature_id = ?,
          disease_id = ?,
          DDD_category_attrib = ?
      WHERE genomic_feature_disease_id = ? 
  });
  $sth->execute(
    $gfd->{genomic_feature_id},
    $gfd->{disease_id},
    $gfd->{DDD_category_attrib},
    $gfd->dbID
  );
  $sth->finish();
  return $gfd;
}


sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;  
  my $constraint = "WHERE genomic_feature_disease_id=$dbID;";
  return $self->_fetch($constraint);  
}

sub fetch_by_GenomicFeature_Disease {
  my $self = shift;
  my $genomic_feature = shift;
  my $disease = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $disease_id = $disease->dbID;
  my $constraint = "WHERE disease_id=$disease_id AND genomic_feature_id=$genomic_feature_id;";
  return $self->_fetch($constraint);  
}

sub fetch_all_by_GenomicFeature {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = "WHERE genomic_feature_id=$genomic_feature_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all_by_Disease {
  my $self = shift;
  my $disease = shift;
  my $disease_id = $disease->dbID;
  my $constraint = "WHERE disease_id=$disease_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all_by_disease_id {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = "WHERE disease_id=$disease_id";
  return $self->_fetch_all($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @genomic_feature_diseases = ();
  my $query = 'SELECT genomic_feature_disease_id, genomic_feature_id, disease_id, DDD_category_attrib FROM genomic_feature_disease';
  $query .= " $constraint;";
  my $dbh = $self->{dbh}; 
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %genomic_feature_disease;
    @genomic_feature_disease{@columns} = @$row;
    $genomic_feature_disease{registry} = $self->{registry};

    if ($genomic_feature_disease{DDD_category_attrib}) {
      $genomic_feature_disease{DDD_category} = $attribute_adaptor->attrib_value_for_id($genomic_feature_disease{DDD_category_attrib});
    }
    push @genomic_feature_diseases, G2P::GenomicFeatureDisease->new(\%genomic_feature_disease);
  } 
  return $genomic_feature_diseases[0]; 
}
 
sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @genomic_feature_diseases = ();
  my $query = 'SELECT genomic_feature_disease_id, genomic_feature_id, disease_id, DDD_category_attrib FROM genomic_feature_disease';
  $query .= " $constraint;";
  my $dbh = $self->{dbh}; 
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %genomic_feature_disease;
    @genomic_feature_disease{@columns} = @$row;
    $genomic_feature_disease{registry} = $self->{registry};

    if ($genomic_feature_disease{DDD_category_attrib}) {
      $genomic_feature_disease{DDD_category} = $attribute_adaptor->attrib_value_for_id($genomic_feature_disease{DDD_category_attrib});
    }
    push @genomic_feature_diseases, G2P::GenomicFeatureDisease->new(\%genomic_feature_disease);
  } 
  return \@genomic_feature_diseases; 
}


1;
