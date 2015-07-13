use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDiseaseAction;
use G2P::GenomicFeatureDiseaseActionLog;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/genomic_feature_disease_action_id genomic_feature_disease_id allelic_requirement_attrib mutation_consequence_attrib/;
my @columns_log = qw/genomic_feature_disease_action_id genomic_feature_disease_id allelic_requirement_attrib mutation_consequence_attrib created user_id action/;

sub store {
  my $self = shift;
  my $GFD_action = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFD_action) || !$GFD_action->isa('G2P::GenomicFeatureDiseaseAction')) {
    die ('G2P::GenomicFeatureDiseaseAction arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }
 
  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_action (
      genomic_feature_disease_id,
      allelic_requirement_attrib,
      mutation_consequence_attrib
    ) VALUES (?,?,?)
  });

  $sth->execute(
    $GFD_action->genomic_feature_disease_id,
    $GFD_action->allelic_requirement_attrib,
    $GFD_action->mutation_consequence_attrib,
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_action', 'genomic_feature_disease_action_id');

  $GFD_action->{genomic_feature_disease_action_id} = $dbID;
  $GFD_action->{registry} = $self->{registry};  

  $self->update_log($GFD_action, $user, 'create');

  return $GFD_action;
}

sub update {
  my $self = shift;
  my $GFD_action = shift;
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFD_action) || !$GFD_action->isa('G2P::GenomicFeatureDiseaseAction')) {
    die ('G2P::GenomicFeatureDiseaseAction arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }
  
  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature_disease_action
      SET genomic_feature_disease_id = ?,
          allelic_requirement_attrib = ?,
          mutation_consequence_attrib = ?
      WHERE genomic_feature_disease_action_id = ?
  });
  $sth->execute(
    $GFD_action->{genomic_feature_disease_id},
    $GFD_action->allelic_requirement_attrib,
    $GFD_action->mutation_consequence_attrib,
    $GFD_action->{genomic_feature_disease_action_id}
  ); 
  $sth->finish();

  $self->update_log($GFD_action, $user, 'update');

  return $GFD_action;
}

sub delete {
  my $self = shift;
  my $GFDA = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFDA) || !$GFDA->isa('G2P::GenomicFeatureDiseaseAction')) {
    die ('G2P::GenomicFeatureDiseaseAction arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }

  $self->update_log($GFDA, $user, 'delete');

  my $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_action WHERE genomic_feature_disease_action_id = ?;
  });
  
  $sth->execute($GFDA->dbID);
  $sth->finish();
}

sub update_log {
  my $self = shift;
  my $GFD_action = shift;
  my $user = shift;
  my $action = shift;
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_action_log(
      genomic_feature_disease_action_id,
      genomic_feature_disease_id,
      allelic_requirement_attrib,
      mutation_consequence_attrib,
      created,
      user_id,
      action 
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?)
  });
  $sth->execute(
    $GFD_action->dbID,
    $GFD_action->genomic_feature_disease_id,
    $GFD_action->allelic_requirement_attrib || undef,
    $GFD_action->mutation_consequence_attrib || undef,
    $user->user_id,
    $action  
  ); 
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
  my $query = 'SELECT genomic_feature_disease_action_id, genomic_feature_disease_id, allelic_requirement_attrib, mutation_consequence_attrib FROM genomic_feature_disease_action';
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

sub fetch_log_entries {
  my $self = shift;
  my $gfda = shift;
  if (!ref($gfda) || !$gfda->isa('G2P::GenomicFeatureDiseaseAction')) {
    die('G2P::GenomicFeatureDiseaseAction arg expected');
  }
  my $dbh = $self->{dbh};
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');

  my $sth = $dbh->prepare(q{
    SELECT genomic_feature_disease_action_id, genomic_feature_disease_id, allelic_requirement_attrib, mutation_consequence_attrib, created, user_id, action FROM genomic_feature_disease_action_log
    WHERE genomic_feature_disease_action_id = ?
    ORDER BY created DESC; 
  }); 
  $sth->execute($gfda->dbID) or die 'Could not execute statement ' . $sth->errstr;
  my @gfda_log_entries = ();
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfda_log;
    @gfda_log{@columns_log} = @$row;
    $gfda_log{registry} = $self->{registry};
    if ($gfda_log{allelic_requirement_attrib}) {
      my @ids = split(',', $gfda_log{allelic_requirement_attrib});
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $gfda_log{allelic_requirement} = join(',', @values);
    }

    if ($gfda_log{mutation_consequence_attrib}) {
      $gfda_log{mutation_consequence} = $attribute_adaptor->attrib_value_for_id($gfda_log{mutation_consequence_attrib});
    }

    push @gfda_log_entries, G2P::GenomicFeatureDiseaseActionLog->new(\%gfda_log);
  } 
  $sth->finish();
  return \@gfda_log_entries;
}

1;
