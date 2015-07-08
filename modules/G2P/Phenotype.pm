use strict;
use warnings;

package G2P::Phenotype;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  
  my $self = bless {
    phenotype_id => $params->{publication_id},
    stable_id => $params->{stable_id},
    name => $params->{name},
    description => $params->{description},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{publication_id};
}

sub stable_id {
  my $self = shift;
  return $self->{stable_id};
}

sub name {
  my $self = shift;
  return $self->{name};
}

sub description {
  my $self = shift;
  return $self->{description};
}

sub source {
  my $self = shift;
  return $self->{source};
}

1;
