use strict;
use warnings;


package G2P::DBSQL::AttributeAdaptor;

use G2P::DBSQL::BaseAdaptor;
our @ISA = ('G2P::DBSQL::BaseAdaptor'); 

sub attrib_value_for_id {
  my ($self, $attrib_id) = @_;

  unless ($self->{attribs}) {
    my $attribs;
    my $attrib_ids;

    my $sql = qq{
      SELECT  a.attrib_id, t.code, a.value
      FROM    attrib a, attrib_type t
      WHERE   a.attrib_type_id = t.attrib_type_id
    };

    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare($sql);

    $sth->execute;

    while (my ($attrib_id, $type, $value) = $sth->fetchrow_array) {
      $attribs->{$attrib_id}->{type}  = $type;
      $attribs->{$attrib_id}->{value} = $value;
      $attrib_ids->{$type}->{$value} = $attrib_id;
    }

    $self->{attribs}    = $attribs;
    $self->{attrib_ids} = $attrib_ids;

  }
  return defined $attrib_id ? $self->{attribs}->{$attrib_id}->{value} : undef;
}

sub attrib_id_for_type_value {
  my ($self, $type, $value) = @_;
  unless ($self->{attrib_ids}) {
    # call this method to populate the attrib hash
    $self->attrib_value_for_id;
  }

  return $self->{attrib_ids}->{$type}->{$value};
}

sub get_attribs_by_type_value {
  my ($self, $attrib_type_code) = @_;
  my $attribs = {};
  my $sql = qq{
    SELECT  a.attrib_id, a.value
    FROM    attrib a, attrib_type t
    WHERE   a.attrib_type_id = t.attrib_type_id
    AND     t.code = ?;
  };

  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($sql);
  $sth->execute($attrib_type_code);

  while (my ($attrib_id, $value) = $sth->fetchrow_array) {
    $attribs->{$value} = $attrib_id;
  }
  $sth->finish();
  return $attribs;
}


1;
