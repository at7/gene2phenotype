use strict;
use warnings;

package G2P::DBSQL::GFDPublicationCommentAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GFDPublicationComment;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/GFD_publication_comment_id GFD_publication_id comment_text created user_id/;

sub store {
  my $self = shift;
  my $GFD_publication_comment = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFD_publication_comment) || !$GFD_publication_comment->isa('G2P::GFDPublicationComment')) {
    die ('G2P::GFDPublicationComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }
 
  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_publication_comment (
      GFD_publication_id,
      comment_text,
      created,
      user_id
    ) VALUES (?,?,CURRENT_TIMESTAMP,?)
  });

  $sth->execute(
    $GFD_publication_comment->get_GFD_publication()->dbID(),
    $GFD_publication_comment->comment_text,
    $user->user_id 
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'GFD_publication_comment', 'GFD_publication_comment_id');

  $GFD_publication_comment->{GFD_publication_comment_id} = $dbID;
  $GFD_publication_comment->{registry} = $self->{registry};  

  return $GFD_publication_comment;
}

sub delete {
  my $self = shift;
  my $GFD_publication_comment = shift; 
  my $user = shift;
  my $dbh = $self->{dbh};

  if (!ref($GFD_publication_comment) || !$GFD_publication_comment->isa('G2P::GFDPublicationComment')) {
    die ('G2P::GFDPublicationComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('G2P::User')) {
    die ('G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_publication_comment_delete (
      GFD_publication_comment_id,
      GFD_publication_id,
      comment_text,
      created,
      user_id,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $GFD_publication_comment->dbID,
    $GFD_publication_comment->GFD_publication_id,
    $GFD_publication_comment->comment_text,
    $GFD_publication_comment->created,
    $GFD_publication_comment->{user_id},
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM GFD_publication_comment WHERE GFD_publication_comment_id = ?;
  });
  
  $sth->execute($GFD_publication_comment->dbID);
  $sth->finish();
}

sub fetch_all_by_GenomicFeatureDiseasePublication {
  my $self = shift;
  my $GFD_publication = shift;
  if (!ref($GFD_publication) || !$GFD_publication->isa('G2P::GenomicFeatureDiseasePublication')) {
    die('G2P::GenomicFeatureDiseasePublication arg expected');
  }
  my $GFD_publication_id = $GFD_publication->dbID;
  my $constraint = "WHERE GFD_publication_id=$GFD_publication_id"; 
  return $self->_fetch_all($constraint);  
}

sub _fetch_all {
  my $self = shift;
  my $constraint = shift;
  my @gfd_publication_comments = ();
  my $query = 'SELECT GFD_publication_comment_id, GFD_publication_id, comment_text, created, user_id FROM GFD_publication_comment';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %gfd_publication_comment;
    @gfd_publication_comment{@columns} = @$row;
    $gfd_publication_comment{registry} = $self->{registry};
    push @gfd_publication_comments, G2P::GFDPublicationComment->new(\%gfd_publication_comment);
  }
  return \@gfd_publication_comments;
}

1;
