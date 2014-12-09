use strict;
use warnings;

package G2P::Disease;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;

  my $self = bless {
    disease_id => $params->{disease_id},
    name => $params->{name},
    mim => $params->{mim},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{disease_id};
}

sub name {
  my $self = shift;
  return $self->{name};  
}

sub mim {
  my $self = shift;
  return $self->{mim};
}

sub get_all_GenomicFeatureDiseases {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_disease_adaptor = $registry->get_adaptor('genomic_feature_disease');
  return $genomic_feature_disease_adaptor->fetch_all_by_disease_id($self->dbID);
}

sub get_all_Variations {
  my $self = shift;
  my $registry = $self->{registry};
  my $variation_adaptor = $registry->get_adaptor('variation');
  return $variation_adaptor->fetch_all_by_disease_id($self->dbID);
}

1;
