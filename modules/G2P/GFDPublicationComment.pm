use strict;
use warnings;

package G2P::GFDPublicationComment;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;
  my $self = bless {
    GFD_publication_comment_id => $params->{GFD_publication_comment_id},
    GFD_publication_id => $params->{GFD_publication_id},
    comment_text => $params->{comment_text}, 
    created => $params->{created},
    user_id => $params->{user_id},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_publication_comment_id};
}

sub comment_text {
  my $self = shift;
  $self->{'comment_text'} = shift if ( @_ );
  return $self->{'comment_text'};
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

1;
