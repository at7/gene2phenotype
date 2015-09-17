use strict;
use warnings;

package G2P::DBSQL::GenomicFeatureDiseaseAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GenomicFeatureDisease;
use G2P::GenomicFeatureDiseaseLog;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/genomic_feature_disease_id genomic_feature_id disease_id DDD_category_attrib is_visible panel/;
my @columns_log = qw/genomic_feature_disease_id genomic_feature_id disease_id DDD_category_attrib is_visible created user_id action/;

sub store {
  my $self = shift;
  my $gfd = shift;
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($gfd) || !$gfd->isa('G2P::GenomicFeatureDisease')) {
    die('G2P::GenomicFeatureDisease arg expected');
  }

  if (!ref($user) || !$user->isa('G2P::User')) {
    die('G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease(
      genomic_feature_id,
      disease_id,
      DDD_category_attrib,
      is_visible,
      panel
    ) VALUES (?, ?, ?, ?, ?)
  });

  $sth->execute(
    $gfd->{genomic_feature_id},
    $gfd->{disease_id},
    $gfd->DDD_category_attrib || undef,
    $gfd->is_visible || 1,
    $gfd->panel,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease', 'genomic_feature_disease_id'); 
  $gfd->{genomic_feature_disease_id} = $dbID;
  $gfd->{registry} = $self->{registry};

  $self->update_log($gfd, $user, 'create');

  return $gfd;
}

sub update {
  my $self = shift;
  my $gfd = shift;
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($gfd) || !$gfd->isa('G2P::GenomicFeatureDisease')) {
    die('G2P::GenomicFeatureDisease arg expected');
  }

  if (!ref($user) || !$user->isa('G2P::User')) {
    die('G2P::User arg expected');
  }
  
  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature_disease
      SET genomic_feature_id = ?,
          disease_id = ?,
          DDD_category_attrib = ?,
          is_visible = ?,
          panel = ?
      WHERE genomic_feature_disease_id = ? 
  });
  $sth->execute(
    $gfd->{genomic_feature_id},
    $gfd->{disease_id},
    $gfd->{DDD_category_attrib},
    $gfd->{is_visible},
    $gfd->{panel},
    $gfd->dbID
  );
  $sth->finish();

  $self->update_log($gfd, $user, 'update');

  return $gfd;
}

sub update_log {
  my $self = shift;
  my $gfd = shift;
  my $user = shift;
  my $action = shift;
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_log(
      genomic_feature_disease_id,
      genomic_feature_id,
      disease_id,
      DDD_category_attrib,
      is_visible,
      created,
      user_id,
      action
    ) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?)
  }); 
  $sth->execute(
    $gfd->dbID,
    $gfd->genomic_feature_id,
    $gfd->disease_id,
    $gfd->DDD_category_attrib || undef,
    $gfd->is_visible || 1,
    $user->user_id,
    $action
  );
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;  
  my $constraint = "WHERE genomic_feature_disease_id=$dbID;";
  return $self->_fetch($constraint);  
}

sub fetch_by_GenomicFeature_Disease {
  my $self = shift;
  my $genomic_feature = shift;
  my $disease = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $disease_id = $disease->dbID;
  my $constraint = "WHERE disease_id=$disease_id AND genomic_feature_id=$genomic_feature_id;";
  return $self->_fetch($constraint);  
}

sub fetch_all_by_GenomicFeature {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = "WHERE genomic_feature_id=$genomic_feature_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all_by_Disease {
  my $self = shift;
  my $disease = shift;
  my $disease_id = $disease->dbID;
  my $constraint = "WHERE disease_id=$disease_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all_by_disease_id {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = "WHERE disease_id=$disease_id";
  return $self->_fetch_all($constraint);
}

sub fetch_all {
  my $self = shift;
  return $self->_fetch_all('');
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @genomic_feature_diseases = ();
  my $query = 'SELECT genomic_feature_disease_id, genomic_feature_id, disease_id, DDD_category_attrib, is_visible, panel FROM genomic_feature_disease';
  $query .= " $constraint;";
  my $dbh = $self->{dbh}; 
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %genomic_feature_disease;
    @genomic_feature_disease{@columns} = @$row;
    $genomic_feature_disease{registry} = $self->{registry};

    if ($genomic_feature_disease{DDD_category_attrib}) {
      $genomic_feature_disease{DDD_category} = $attribute_adaptor->attrib_value_for_id($genomic_feature_disease{DDD_category_attrib});
    }
    push @genomic_feature_diseases, G2P::GenomicFeatureDisease->new(\%genomic_feature_disease);
  } 
  return $genomic_feature_diseases[0]; 
}
 
sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @genomic_feature_diseases = ();
  my $query = 'SELECT genomic_feature_disease_id, genomic_feature_id, disease_id, DDD_category_attrib, is_visible, panel FROM genomic_feature_disease';
  $query .= " $constraint;";
  my $dbh = $self->{dbh}; 
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %genomic_feature_disease;
    @genomic_feature_disease{@columns} = @$row;
    $genomic_feature_disease{registry} = $self->{registry};

    if ($genomic_feature_disease{DDD_category_attrib}) {
      $genomic_feature_disease{DDD_category} = $attribute_adaptor->attrib_value_for_id($genomic_feature_disease{DDD_category_attrib});
    }
  
    if ($genomic_feature_disease{panel}) {
      $genomic_feature_disease{panel} = $attribute_adaptor->attrib_value_for_id($genomic_feature_disease{panel});
    }

    push @genomic_feature_diseases, G2P::GenomicFeatureDisease->new(\%genomic_feature_disease);
  } 
  return \@genomic_feature_diseases; 
}

sub fetch_log_entries {
  my $self = shift;
  my $gfd = shift;
  if (!ref($gfd) || !$gfd->isa('G2P::GenomicFeatureDisease')) {
    die('G2P::GenomicFeatureDisease arg expected');
  }
  my $dbh = $self->{dbh};
  my $registry = $self->{registry};
  my $attribute_adaptor = $registry->get_adaptor('attribute');

  my $sth = $dbh->prepare(q{
    SELECT genomic_feature_disease_id, genomic_feature_id, disease_id, DDD_category_attrib, is_visible, created, user_id, action FROM genomic_feature_disease_log
    WHERE genomic_feature_disease_id = ?
    ORDER BY created DESC; 
  }); 
  $sth->execute($gfd->dbID) or die 'Could not execute statement ' . $sth->errstr;
  my @gfd_log_entries = ();
  while (my $row = $sth->fetchrow_arrayref()) {
    my %genomic_feature_disease_log;
    @genomic_feature_disease_log{@columns_log} = @$row;
    $genomic_feature_disease_log{registry} = $self->{registry};

    if ($genomic_feature_disease_log{DDD_category_attrib}) {
      $genomic_feature_disease_log{DDD_category} = $attribute_adaptor->attrib_value_for_id($genomic_feature_disease_log{DDD_category_attrib});
    }
    push @gfd_log_entries, G2P::GenomicFeatureDiseaseLog->new(\%genomic_feature_disease_log);
  } 
  $sth->finish();
  return \@gfd_log_entries;
}

1;
