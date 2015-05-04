use strict;
use warnings;

package G2P::GenomicFeatureDiseaseAction;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    genomic_feature_disease_action_id => $params->{genomic_feature_disease_action_id}, 
    genomic_feature_disease_id => $params->{genomic_feature_disease_id},
    allelic_requirement => $params->{allelic_requirement} || undef,
    allelic_requirement_attrib => $params->{allelic_requirement_attrib},
    mutation_consequence => $params->{mutation_consequence} || undef, 
    mutation_consequence_attrib => $params->{mutation_consequence_attrib}, 
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{genomic_feature_disease_action_id};
}

sub genomic_feature_disease_id {
  my $self = shift;
  return $self->{genomic_feature_disease_id};
}

sub allelic_requirement {
  my $self = shift;
  return $self->{allelic_requirement};
}

sub allelic_requirement_attrib {
  my $self = shift;
  $self->{allelic_requirement_attrib} = shift if @_;
  return $self->{allelic_requirement_attrib};
}

sub mutation_consequence {
  my $self = shift;
  return $self->{mutation_consequence};
}

sub mutation_consequence_attrib {
  my $self = shift;
  $self->{mutation_consequence_attrib} = shift if @_;
  return $self->{mutation_consequence_attrib};
}


1;
