use strict;
use warnings;

package G2P::EnsemblVariant;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;

  my $self = bless {
    variant_id => $params->{variant_id},
    genomic_feature_id => $params->{genomic_feature_id},
    seq_region => $params->{seq_region},
    seq_region_start => $params->{seq_region_start},
    seq_region_end => $params->{seq_region_end},
    seq_region_strand => $params->{seq_region_strand},
    name => $params->{name},
    source => $params->{source},
    allele_string => $params->{allele_string},
    consequence => $params->{consequence},
    feature_stable_id => $params->{feature_stable_id},
    amino_acid_string => $params->{amino_acid_string},
    polyphen_prediction => $params->{polyphen_prediction},
    sift_prediction => $params->{sift_prediction},
    registry => $params->{registry}, 
  }, $class;
  return $self;
}

sub variant_id {
  my $self = shift;
  return $self->{variant_id};
}

sub genomic_feature_id {
  my $self = shift;
  return $self->{genomic_feature_id};
}

sub seq_region {
  my $self = shift;
  return $self->{seq_region};
}

sub seq_region_start {
  my $self = shift;
  return $self->{seq_region_start};
}

sub seq_region_end {
  my $self = shift;
  return $self->{seq_region_end};
}

sub seq_region_strand {
  my $self = shift;
  return $self->{seq_region_strand};
}

sub name {
  my $self = shift;
  return $self->{name};
}

sub source {
  my $self = shift;
  return $self->{source};
}

sub allele_string {
  my $self = shift;
  return $self->{allele_string};
}

sub consequence {
  my $self = shift;
  return $self->{consequence};
}

sub feature_stable_id {
  my $self = shift;
  return $self->{feature_stable_id};
}

sub amino_acid_string {
  my $self = shift;
  return $self->{amino_acid_string};
}

sub polyphen_prediction {
  my $self = shift;
  return $self->{polyphen_prediction};
}

sub sift_prediction {
  my $self = shift;
  return $self->{sift_prediction};
}

1;
