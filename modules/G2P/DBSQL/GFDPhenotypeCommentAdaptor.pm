use strict;
use warnings;

package G2P::DBSQL::GFDPhenotypeCommentAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GFDPhenotypeComment;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/GFD_phenotype_comment_id GFD_phenotype_id comment_text created user_id/;

sub store {
  my $self = shift;
  my $GFD_phenotype_comment = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFD_phenotype_comment) || !$GFD_phenotype_comment->isa('G2P::GFDPhenotypeComment')) {
    die ('G2P::GFDPhenotypeComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }
 
  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_phenotype_comment (
      GFD_phenotype_id,
      comment_text,
      created,
      user_id
    ) VALUES (?,?,CURRENT_TIMESTAMP,?)
  });

  $sth->execute(
    $GFD_phenotype_comment->get_GFD_phenotype()->dbID(),
    $GFD_phenotype_comment->comment_text,
    $user->user_id 
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'GFD_phenotype_comment', 'GFD_phenotype_comment_id');

  $GFD_phenotype_comment->{GFD_phenotype_comment_id} = $dbID;
  $GFD_phenotype_comment->{registry} = $self->{registry};  

  return $GFD_phenotype_comment;
}

sub delete {
  my $self = shift;
  my $GFD_phenotype_comment = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFD_phenotype_comment) || !$GFD_phenotype_comment->isa('G2P::GFDPhenotypeComment')) {
    die ('G2P::GFDPhenotypeComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_phenotype_comment_deleted (
      GFD_phenotype_id,
      comment_text,
      created,
      user_id,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $GFD_phenotype_comment->GFD_phenotype_id,
    $GFD_phenotype_comment->comment_text,
    $GFD_phenotype_comment->created,
    $GFD_phenotype_comment->{user_id},
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM GFD_phenotype_comment WHERE GFD_phenotype_comment_id = ?;
  });
  
  $sth->execute($GFD_phenotype_comment->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_phenotype_comment_id = shift;
  my $constraint = "WHERE GFD_phenotype_comment_id=$GFD_phenotype_comment_id"; 
  return $self->_fetch($constraint);  
}

sub fetch_all_by_GenomicFeatureDiseasePhenotype {
  my $self = shift;
  my $GFD_phenotype = shift;
  if (!ref($GFD_phenotype) || !$GFD_phenotype->isa('G2P::GenomicFeatureDiseasePhenotype')) {
    die('G2P::GenomicFeatureDiseasePhenotype arg expected');
  }
  my $GFD_phenotype_id = $GFD_phenotype->dbID;
  my $constraint = "WHERE GFD_phenotype_id=$GFD_phenotype_id"; 
  return $self->_fetch_all($constraint);  
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @gfd_phenotype_comments = ();
  my $query = 'SELECT GFD_phenotype_comment_id, GFD_phenotype_id, comment_text, created, user_id FROM GFD_phenotype_comment';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_phenotype_comment;
    @gfd_phenotype_comment{@columns} = @$row;
    $gfd_phenotype_comment{registry} = $self->{registry};
    push @gfd_phenotype_comments, G2P::GFDPhenotypeComment->new(\%gfd_phenotype_comment);
  }
  return $gfd_phenotype_comments[0];
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @gfd_phenotype_comments = ();
  my $query = 'SELECT GFD_phenotype_comment_id, GFD_phenotype_id, comment_text, created, user_id FROM GFD_phenotype_comment';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_phenotype_comment;
    @gfd_phenotype_comment{@columns} = @$row;
    $gfd_phenotype_comment{registry} = $self->{registry};
    push @gfd_phenotype_comments, G2P::GFDPhenotypeComment->new(\%gfd_phenotype_comment);
  }
  return \@gfd_phenotype_comments;
}

1;
