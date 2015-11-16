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
    is_visible => $params->{is_visible},
    panel => $params->{panel},
    panel_attrib => $params->{panel_attrib},
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
  my $DDD_category = shift;
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  if ($DDD_category) {
    $self->{DDD_category} = $DDD_category;
    my $DDD_category_attrib = $attribute_adaptor->attrib_id_for_value($DDD_category);
    $self->DDD_category_attrib($DDD_category_attrib);
  } else {
    if (!$self->{DDD_category} && $self->{DDD_category_attrib}) {
      $self->{DDD_category} = $attribute_adaptor->attrib_value_for_id($self->{DDD_category_attrib});
    }
  }
  return $self->{DDD_category};
}

sub DDD_category_attrib {
  my $self = shift;
  my $DDD_category_attrib = shift;
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  if ($DDD_category_attrib) {
    $self->{DDD_category_attrib} = $DDD_category_attrib;
    $self->{DDD_category} = $attribute_adaptor->attrib_value_for_id($self->{DDD_category_attrib});
  } else {
    if (!$self->{DDD_category_attrib} && $self->{DDD_category}) {
      $self->{DDD_category_attrib} = $attribute_adaptor->attrib_id_for_value($self->{DDD_category});
    }
  }
  return $self->{DDD_category_attrib};
}

sub is_visible {
  my $self = shift;
  $self->{is_visible} = shift if ( @_ );
  return $self->{is_visible};
}

sub panel {
  my $self = shift;
  my $panel = shift;
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  if ($panel) {
    $self->{panel} = $panel;
    $self->{panel_attrib} = $attribute_adaptor->attrib_id_for_value($self->{panel});
  } else {
    if (!$self->{panel} && $self->{panel_attrib}) {
      $self->{panel} = $attribute_adaptor->attrib_value_for_id($self->{panel_attrib});
    }
  }
  return $self->{panel};
}

sub panel_attrib {
  my $self = shift;
  my $panel_attrib = shift;
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  if ($panel_attrib) {
    $self->{panel_attrib} = $panel_attrib;
    $self->{panel} = $attribute_adaptor->attrib_value_for_id($self->{panel_attrib});
  } else {
    if (!$self->{panel_attrib} && $self->{panel}) {
      $self->{panel_attrib} = $attribute_adaptor->attrib_id_for_value($self->{panel});  
    }
  }

  return $self->{panel_attrib};
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

sub get_all_GFDPublications {
  my $self = shift;
  my $registry = $self->{registry};
  my $GFD_publication_adaptor = $registry->get_adaptor('genomic_feature_disease_publication');
  return $GFD_publication_adaptor->fetch_all_by_GenomicFeatureDisease($self);
}

sub get_all_GFDPhenotypes {
  my $self = shift;
  my $registry = $self->{registry};
  my $GFD_phenotype_adaptor = $registry->get_adaptor('genomic_feature_disease_phenotype');
  return $GFD_phenotype_adaptor->fetch_all_by_GenomicFeatureDisease($self);
}

sub get_all_GFDOrgans {
  my $self = shift;
  my $registry = $self->{registry};
  my $GFD_organ_adaptor = $registry->get_adaptor('genomic_feature_disease_organ');
  return $GFD_organ_adaptor->fetch_all_by_GenomicFeatureDisease($self);
}

1;
