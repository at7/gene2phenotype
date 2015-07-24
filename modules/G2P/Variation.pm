use strict;
use warnings;

package G2P::Variation;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;

  my $self = bless {
    variation_id => $params->{variation_id},
    genomic_feature_id => $params->{genomic_feature_id},
    disease_id => $params->{disease_id},
    publication_id => $params->{publication_id},
    mutation => $params->{mutation},
    consequence => $params->{consequence}, 
    synonyms => $params->{synonyms},
    registry => $params->{registry}, 
  }, $class;
  return $self;
}

sub variation_id {
  my $self = shift;
  return $self->{variation_id};
}

sub genomic_feature_id {
  my $self = shift;
  return $self->{genomic_feature_id};
}

sub disease_id {
  my $self = shift;
  return $self->{disease_id};
}

sub mutation {
  my $self = shift;
  return $self->{mutation};
}

sub consequence {
  my $self = shift;
  return $self->{consequence};
}

sub publication_id {
  my $self = shift;
  return $self->{publication_id};
}

sub get_all_synonyms_order_by_source {
  my $self = shift;
  my $registry = $self->{registry};
  my $variation_adaptor = $registry->get_adaptor('variation');
  return $variation_adaptor->fetch_all_synonyms_order_by_source_by_variation_id($self->{variation_id});
}

sub get_Publication {
  my $self = shift;
  unless ($self->{publication_id}) {
    return undef;
  }
  my $registry = $self->{registry};
  my $publication_adaptor = $registry->get_adaptor('publication');
  return $publication_adaptor->fetch_by_dbID($self->{publication_id});
}

sub get_GenomicFeature {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_adaptor = $registry->get_adaptor('genomic_feature');
  return $genomic_feature_adaptor->fetch_by_dbID($self->{genomic_feature_id});
}

sub get_GenomicFeatureDisease {


}



1;
