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
    $GFD_publication_comment->comment,
    $user->user_id 
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'GFD_publication_comment', 'GFD_publication_comment_id');

  $GFD_publication_comment->{GFD_publication_comment_id} = $dbID;
  $GFD_publication_comment->{registry} = $self->{registry};  

  return $GFD_publication_comment;
}

sub fetch_all_by_GenomicFeatureDiseasePublication {
  



}




1;
