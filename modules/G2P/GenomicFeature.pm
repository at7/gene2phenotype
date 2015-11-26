use strict;
use warnings;

package G2P::GenomicFeature;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    genomic_feature_id => $params->{genomic_feature_id},
    gene_symbol        => $params->{gene_symbol},
    mim                => $params->{mim},
    ensembl_stable_id  => $params->{ensembl_stable_id},
    synonyms           => $params->{synonyms},
    registry           => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{genomic_feature_id};
}

sub genomic_feature_id {
  my $self = shift;
  return $self->{genomic_feature_id};
}

sub gene_symbol {
  my $self = shift;
  $self->{gene_symbol} = shift if @_;
  return $self->{gene_symbol};
}

sub mim {
  my $self = shift;
  $self->{mim} = shift if @_;
  return $self->{mim};
}

sub ensembl_stable_id {
  my $self = shift;
  $self->{ensembl_stable_id} = shift if @_;
  return $self->{ensembl_stable_id};
}

sub get_all_Variations {
  my $self = shift;
  my $registry = $self->{registry};
  my $variation_adaptor = $registry->get_adaptor('variation');
  return $variation_adaptor->fetch_all_by_genomic_feature_id($self->genomic_feature_id);
}

sub synonyms {
  my $self = shift;
  my $synonyms =  join(' ', @{$self->{synonyms}});
  return $synonyms;
}

sub get_organ_specificity_list {
  my $self = shift;
  unless ($self->{organ_specificity_list}) {
    my $registry = $self->{registry};
    my $organ_specificty_adaptor = $registry->get_adaptor('organ_specificity');
    my $organ_list = '';
    $organ_list = $organ_specificty_adaptor->fetch_list_by_GenomicFeature($self);
    $self->{organ_specificity_list} = $organ_list;
  }
  return $self->{organ_specificity_list};
}


1;
