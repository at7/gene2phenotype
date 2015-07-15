use strict;
use warnings;

package G2P::Phenotype;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  
  my $self = bless {
    phenotype_id => $params->{phenotype_id},
    stable_id => $params->{stable_id},
    name => $params->{name},
    description => $params->{description},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{phenotype_id};
}

sub stable_id {
  my $self = shift;
  $self->{stable_id} = shift if @_;
  return $self->{stable_id};
}

sub name {
  my $self = shift;
  $self->{name} = shift if @_;
  return $self->{name};
}

sub description {
  my $self = shift;
  $self->{description} = shift if @_;
  return $self->{description};
}


1;
