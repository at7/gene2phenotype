use strict;
use warnings;

package G2P::GenomicFeatureDiseasePhenotype;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    GFD_phenotype_id => $params->{GFD_phenotype_id},
    genomic_feature_disease_id => $params->{genomic_feature_disease_id},
    phenotype_id => $params->{phenotype_id},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_phenotype_id};
}

sub get_GenomicFeatureDisease {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_disease_adaptor = $registry->get_adaptor('genomic_feature_disease');
  return $genomic_feature_disease_adaptor->fetch_by_dbID($self->{genomic_feature_disease_id});
}

sub get_Phenotype {
  my $self = shift;
  my $registry = $self->{registry};
  my $phenotype_adaptor = $registry->get_adaptor('phenotype');
  return $phenotype_adaptor->fetch_by_dbID($self->{phenotype_id});
}

1;
