use strict;
use warnings;

package G2P::VariationSynonym;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;

  my $self = bless {
    variation_id => $params->{variation_id},
    name => $params->{name},
    source => $params->{source},
    registry => $params->{registry}, 
  }, $class;
  return $self;
}

sub variation_id {
  my $self = shift;
  return $self->{variation_id};
}

sub name {
  my $self = shift;
  return $self->{name};
}

sub source {
  my $self = shift;
  return $self->{source};
}


1;
