use strict;
use warnings;

package G2P::GenomicFeatureDiseasePublication;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    GFD_publication_id => $params->{GFD_publication_id},
    genomic_feature_disease_id => $params->{genomic_feature_disease_id},
    publication_id => $params->{publication_id},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_publication_id};
}

sub get_GenomicFeatureDisease {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_disease_adaptor = $registry->get_adaptor('genomic_feature_disease');
  return $genomic_feature_disease_adaptor->fetch_by_dbID($self->{genomic_feature_disease_id});
}

sub get_Publication {
  my $self = shift;
  my $registry = $self->{registry};
  my $publication_adaptor = $registry->get_adaptor('publication');
  return $publication_adaptor->fetch_by_dbID($self->{publication_id});
}

sub get_all_GFDPublicationComments {
  my $self = shift;
  my $registry = $self->{registry};
  my $GFD_publication_comment_adaptor = $registry->get_adaptor('GFD_publication_comment');
  return $GFD_publication_comment_adaptor->fetch_by_dbID($self->{GFD_publication_id});
}


1;
