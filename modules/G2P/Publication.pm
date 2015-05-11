use strict;
use warnings;

package G2P::Publication;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  
  my $self = bless {
    publication_id => $params->{publication_id},
    pmid => $params->{pmid},
    title => $params->{title},
    source => $params->{source},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{publication_id};
}

sub publication_id {
  my $self = shift;
  return $self->{publication_id};
}

sub pmid {
  my $self = shift;
  return $self->{pmid};
}

sub title {
  my $self = shift;
  return $self->{title};
}

sub source {
  my $self = shift;
  return $self->{source};
}

1;
