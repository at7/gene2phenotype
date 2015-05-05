use strict;
use warnings;

package G2P::DBSQL::GFDPublicationCommentAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::GFDPublicationComment;

our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/GFD_publication_comment_id GFD_publication_id comment_text created user_id/;




1;
