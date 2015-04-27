use strict;
use warnings;


package G2P::GenomicFeatureDiseaseLog;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    genomic_feature_disease_id => $params->{genomic_feature_disease_id},
    genomic_feature_id => $params->{genomic_feature_id},
    disease_id => $params->{disease_id},
    DDD_category => $params->{DDD_category},
    DDD_category_attrib => $params->{DDD_category_attrib},
    created => $params->{created},
    user_id => $params->{user_id},
    action => $params->{action},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{genomic_feature_disease_id};
}

sub DDD_category {
  my $self = shift;
  return $self->{DDD_category};
}

sub DDD_category_attrib {
  my $self = shift;
  $self->{DDD_category_attrib} = shift if ( @_ );
  return $self->{DDD_category_attrib};
}

sub get_GenomicFeature {
  my $self = shift;
  my $registry = $self->{registry};
  my $genomic_feature_adaptor = $registry->get_adaptor('genomic_feature');
  return $genomic_feature_adaptor->fetch_by_dbID($self->{genomic_feature_id});
}

sub get_Disease {
  my $self = shift;
  my $registry = $self->{registry}; 
  my $disease_adaptor = $registry->get_adaptor('disease');
  return $disease_adaptor->fetch_by_dbID($self->{disease_id});
}

sub get_User {
  my $self = shift;
  my $registry = $self->{registry};
  my $user_adaptor = $registry->get_adaptor('user');
  return $user_adaptor->fetch_by_dbID($self->{user_id});
}

sub created {
  my $self = shift;
  $self->{'created'} = shift if ( @_ );
  return $self->{'created'};
}

sub action {
  my $self = shift;
  $self->{'action'} = shift if ( @_ );
  return $self->{'action'};
} 

1;
