use strict;
use warnings;

package G2P::User;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my $params = shift;

  my $self = bless {
    user_id => $params->{user_id},
    username => $params->{username},
    email => $params->{email},
    panel => $params->{panel},
    panel_attrib => $params->{panel_attrib},
    registry => $params->{registry},
  }, $class;
  return $self;
}

sub user_id {
  my $self = shift;
  return $self->{user_id};
}

sub username {
  my $self = shift;
  return $self->{username};
}

sub email {
  my $self = shift;
  return $self->{email};
}

sub panel {
  my $self = shift;
  my $panel = shift;
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  if ($panel) {
    $self->{panel} = $panel;
    $self->{panel_attrib} = $attribute_adaptor->attrib_id_for_value($self->{panel});
  } else {
    if (!$self->{panel} && $self->{panel_attrib}) {
      $self->{panel} = $attribute_adaptor->attrib_value_for_id($self->{panel_attrib});
    }
  }
  return $self->{panel};
}

sub panel_attrib {
  my $self = shift;
  my $panel_attrib = shift;
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  if ($panel_attrib) {
    $self->{panel_attrib} = $panel_attrib;
    $self->{panel} = $attribute_adaptor->attrib_value_for_id($self->{panel_attrib});
  } else {
    if (!$self->{panel_attrib} && $self->{panel}) {
      $self->{panel_attrib} = $attribute_adaptor->attrib_id_for_value($self->{panel});
    }
  }

  return $self->{panel_attrib};
}

1;
