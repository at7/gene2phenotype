use strict;
use warnings;

package G2P::Registry;

use DBI;
use FileHandle;
use G2P::DBSQL::DiseaseAdaptor;
use G2P::DBSQL::VariationAdaptor;
use G2P::DBSQL::GenomicFeatureAdaptor;
use G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor;
use G2P::DBSQL::GenomicFeatureDiseaseAdaptor;
use G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor;
use G2P::DBSQL::GenomicFeatureDiseasePhenotypeAdaptor;
use G2P::DBSQL::GenomicFeatureDiseaseOrganAdaptor;
use G2P::DBSQL::GFDPublicationCommentAdaptor;
use G2P::DBSQL::GFDPhenotypeCommentAdaptor;
use G2P::DBSQL::PublicationAdaptor;
use G2P::DBSQL::PhenotypeAdaptor;
use G2P::DBSQL::OrganAdaptor;
use G2P::DBSQL::OrganSpecificityAdaptor;
use G2P::DBSQL::UserAdaptor;
use G2P::DBSQL::AttributeAdaptor;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my $configuration_file = shift;

  my $self = bless {
    configuration_file => $configuration_file, 
  }, $class;

  $self->db_connection();

  return $self;
}

sub get_adaptor {
  my $self = shift;
  my $adaptor = shift;

  if ($adaptor eq 'disease') {
    return G2P::DBSQL::DiseaseAdaptor->new($self);
  } elsif ($adaptor eq 'variation') {
    return G2P::DBSQL::VariationAdaptor->new($self);
  } elsif ($adaptor eq 'genomic_feature') {
    return G2P::DBSQL::GenomicFeatureAdaptor->new($self);
  } elsif ($adaptor eq 'genomic_feature_disease') {
    return G2P::DBSQL::GenomicFeatureDiseaseAdaptor->new($self);
  } elsif ($adaptor eq 'genomic_feature_disease_action') {
    return G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor->new($self);
  } elsif ($adaptor eq 'organ') {
    return G2P::DBSQL::OrganAdaptor->new($self);
  } elsif ($adaptor eq 'publication') {
    return G2P::DBSQL::PublicationAdaptor->new($self);
  } elsif ($adaptor eq 'phenotype') {
    return G2P::DBSQL::PhenotypeAdaptor->new($self);
  } elsif ($adaptor eq 'organ_specificity') {
    return G2P::DBSQL::OrganSpecificityAdaptor->new($self);
  } elsif ($adaptor eq 'user') {
    return G2P::DBSQL::UserAdaptor->new($self);
  } elsif ($adaptor eq 'attribute') {
    return G2P::DBSQL::AttributeAdaptor->new($self);
  } elsif ($adaptor eq 'genomic_feature_disease_organ') {
    return G2P::DBSQL::GenomicFeatureDiseaseOrganAdaptor->new($self);
  } elsif ($adaptor eq 'genomic_feature_disease_publication') {
    return G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor->new($self);
  } elsif ($adaptor eq 'genomic_feature_disease_phenotype') {
    return G2P::DBSQL::GenomicFeatureDiseasePhenotypeAdaptor->new($self);
  } elsif ($adaptor eq 'GFD_publication_comment') {
    return G2P::DBSQL::GFDPublicationCommentAdaptor->new($self);
  } elsif ($adaptor eq 'GFD_phenotype_comment') {
    return G2P::DBSQL::GFDPhenotypeCommentAdaptor->new($self);
  } else {
    die "No adaptor found for $adaptor\n"; 
  }
}

sub db_connection {
  my $self = shift;
  my $fh = FileHandle->new($self->{configuration_file}, 'r'); 

  while (<$fh>) {
    chomp;
    my ($db_connection_parameter, $value) = split /=/;
    $self->{$db_connection_parameter} = $value;
  }
  $fh->close();
  my $host = $self->{host};
  my $database = $self->{database};
  my $user = $self->{user};
  my $password = $self->{password};
  my $port = $self->{port};
  my $dbh = DBI->connect("DBI:mysql:host=$host;database=$database;port=$port", $user, $password, {'RaiseError' => 1});
  $self->{dbh} = $dbh;
}


sub new_dbh {
  my $self = shift;
  my $fh = FileHandle->new($self->{configuration_file}, 'r'); 

  while (<$fh>) {
    chomp;
    my ($db_connection_parameter, $value) = split /=/;
    $self->{$db_connection_parameter} = $value;
  }
  $fh->close();
  my $host = $self->{host};
  my $database = $self->{database};
  my $user = $self->{user};
  my $password = $self->{password};
  my $port = $self->{port};
  my $dbh = DBI->connect("DBI:mysql:host=$host;database=$database;port=$port", $user, $password, {'RaiseError' => 1});
  return $dbh;
}

sub dbh {
  my $self = shift;
  return $self->{dbh};
}


1;
