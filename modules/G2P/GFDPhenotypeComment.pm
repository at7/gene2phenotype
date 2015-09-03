use strict;
use warnings;

package G2P::GFDPhenotypeComment;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    GFD_phenotype_comment_id => $params->{GFD_phenotype_comment_id},
    GFD_phenotype_id => $params->{GFD_phenotype_id},
    comment_text => $params->{comment_text}, 
    created => $params->{created},
    user_id => $params->{user_id},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_phenotype_comment_id};
}

sub comment_text {
  my $self = shift;
  $self->{'comment_text'} = shift if ( @_ );
  return $self->{'comment_text'};
}

sub GFD_phenotype_id {
  my $self = shift;
  $self->{'GFD_phenotype_id'} = shift if ( @_ );
  return $self->{'GFD_phenotype_id'};
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

sub get_GFD_phenotype {
  my $self = shift;
  my $registry = $self->{registry};
  my $GFD_phenotype_adaptor = $registry->get_adaptor('genomic_feature_disease_phenotype');
  return $GFD_phenotype_adaptor->fetch_by_dbID($self->{GFD_phenotype_id});
}

1;
