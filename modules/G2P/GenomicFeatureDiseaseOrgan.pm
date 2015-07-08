use strict;
use warnings;

package G2P::GenomicFeatureDiseaseOrgan;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    GFD_organ_id => $params->{GFD_organ_id},
    genomic_feature_disease_id => $params->{genomic_feature_disease_id},
    organ_id => $params->{organ_id},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_organ_id};
}

sub get_GenomicFeatureDisease {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_disease_adaptor = $registry->get_adaptor('genomic_feature_disease');
  return $genomic_feature_disease_adaptor->fetch_by_dbID($self->{genomic_feature_disease_id});
}

sub get_Organ {
  my $self = shift;
  my $registry = $self->{registry};
  my $organ_adaptor = $registry->get_adaptor('organ');
  return $organ_adaptor->fetch_by_dbID($self->{organ_id});
}

1;
