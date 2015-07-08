use strict;
use warnings;

package G2P::Organ;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  
  my $self = bless {
    organ_id => $params->{organ_id},
    name => $params->{name},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{organ_id};
}

sub name {
  my $self = shift;
  return $self->{name};
}

1;
