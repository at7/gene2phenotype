use strict;
use warnings;


package G2P::GenomicFeatureDisease;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    genomic_feature_disease_id => $params->{genomic_feature_disease_id},
    genomic_feature_id => $params->{genomic_feature_id},
    disease_id => $params->{disease_id},
    DDD_category => $params->{DDD_category},
    DDD_category_attrib => $params->{DDD_category_attrib},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{genomic_feature_disease_id};
}

sub genomic_feature_id {
  my $self = shift;
  $self->{genomic_feature_id} = shift if ( @_ );
  return $self->{genomic_feature_id};
}

sub disease_id {
  my $self = shift;
  $self->{disease_id} = shift if ( @_ );
  return $self->{disease_id};
}

sub DDD_category {
  my $self = shift;
  return $self->{DDD_category};
}

sub DDD_category_attrib {
  my $self = shift;
  $self->{DDD_category_attrib} = shift if ( @_ );
  return $self->{DDD_category_attrib};
}

sub get_all_GenomicFeatureDiseaseActions {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_disease_action_adaptor = $registry->get_adaptor('genomic_feature_disease_action');
  return $genomic_feature_disease_action_adaptor->fetch_all_by_GenomicFeatureDisease($self);       
}

sub get_GenomicFeature {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_adaptor = $registry->get_adaptor('genomic_feature');
  return $genomic_feature_adaptor->fetch_by_dbID($self->{genomic_feature_id});
}

sub get_Disease {
  my $self = shift;
  my $registry = $self->{registry}; 
  my $disease_adaptor = $registry->get_adaptor('disease');
  return $disease_adaptor->fetch_by_dbID($self->{disease_id});
}

sub get_all_Variations {
  my $self = shift;
  my $registry = $self->{registry};
  my $variation_adaptor = $registry->get_adaptor('variation');
  return $variation_adaptor->fetch_all_by_genomic_feature_id_disease_id($self->{genomic_feature_id}, $self->{disease_id});
}

1;
