use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDiseaseAction;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/genomic_feature_disease_action_id genomic_feature_disease_id allelic_requirement_attrib mutation_consequence_attrib user_id/;

sub store {
  my $self = shift;
  my $GFD_action = shift; 
  my $dbh = $self->{dbh};
  
  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_action (
      genomic_feature_disease_id,
      allelic_requirement_attrib,
      mutation_consequence_attrib,
      user_id
    ) VALUES (?,?,?,?)
  });

  $sth->execute(
    $GFD_action->genomic_feature_disease_id,
    $GFD_action->allelic_requirement_attrib,
    $GFD_action->mutation_consequence_attrib,
    $GFD_action->{user_id}
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_action', 'genomic_feature_disease_action_id');

  $GFD_action->{genomic_feature_disease_action_id} = $dbID;
  $GFD_action->{registry} = $self->{registry};  
  return $GFD_action;
}

sub update {
  my $self = shift;
  my $GFD_action = shift;
  my $dbh = $self->{dbh};
  
  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature_disease_action
      SET genomic_feature_disease_id = ?,
          allelic_requirement_attrib = ?,
          mutation_consequence_attrib = ?,
          user_id = ?
      WHERE genomic_feature_disease_action_id = ?
  });
  $sth->execute(
    $GFD_action->{genomic_feature_disease_id},
    $GFD_action->allelic_requirement_attrib,
    $GFD_action->mutation_consequence_attrib,
    $GFD_action->{user_id},
    $GFD_action->{genomic_feature_disease_action_id}
  ); 
  $sth->finish();
  return $GFD_action;
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  my $constraint = "WHERE genomic_feature_disease_action_id=$dbID;";
  return $self->_fetch($constraint);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $genomic_feature_disease = shift;
  my $gfd_id = $genomic_feature_disease->dbID();
  my $constraint = "WHERE genomic_feature_disease_id=$gfd_id;";
  return $self->_fetch_all($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my $gfd_actions = $self->_fetch_all($constraint);
  if (scalar @$gfd_actions > 0) { 
    return $gfd_actions->[0];
  }
  return undef;
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @gfd_actions = ();
  my $query = 'SELECT genomic_feature_disease_action_id, genomic_feature_disease_id, allelic_requirement_attrib, mutation_consequence_attrib, user_id FROM genomic_feature_disease_action';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute'); 
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_action;
    @gfd_action{@columns} = @$row;
    $gfd_action{registry} = $self->{registry};
 
    if ($gfd_action{allelic_requirement_attrib}) {
      my @ids = split(',', $gfd_action{allelic_requirement_attrib});
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $gfd_action{allelic_requirement} = join(',', @values);
    }

    if ($gfd_action{mutation_consequence_attrib}) {
      $gfd_action{mutation_consequence} = $attribute_adaptor->attrib_value_for_id($gfd_action{mutation_consequence_attrib});
    }

    push @gfd_actions, G2P::GenomicFeatureDiseaseAction->new(\%gfd_action);
  }
  return \@gfd_actions;
}


1;
