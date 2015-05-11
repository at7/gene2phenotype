use strict;
use warnings;

package G2P::DBSQL::PublicationAdaptor;

use G2P::DBSQL::BaseAdaptor;
use G2P::Publication;
our @ISA = ('G2P::DBSQL::BaseAdaptor');

my @columns = qw/publication_id pmid title source/;

sub store {
  my $self = shift;
  my $publication = shift;  
  my $dbh = $self->{dbh};

  my $sth = $dbh->prepare(q{
    INSERT INTO publication (
      pmid,
      title,
      source
    ) VALUES (?,?,?);
  });
  $sth->execute(
    $publication->pmid || undef,
    $publication->title || undef,
    $publication->source || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'publication', 'publication_id');
  $publication->{publication_id} = $dbID;
  $publication->{registry} = $self->{registry};
  return $publication;
}

sub fetch_by_publication_id {
  my $self = shift;
  my $publication_id = shift;
  my $constraint = "WHERE publication_id=$publication_id";
  return $self->_fetch($constraint);
}

sub fetch_by_dbID {
  my $self = shift;
  my $publication_id = shift;
  my $constraint = "WHERE publication_id=$publication_id";
  return $self->_fetch($constraint);
}

sub fetch_by_PMID {
  my $self = shift;
  my $pmid = shift;
  my $constraint = "WHERE pmid=$pmid";
  return $self->_fetch($constraint);
}

sub _fetch {
  my $self = shift;
  my $constraint = shift;
  my @publications = ();
  my $query = 'SELECT publication_id, pmid, title, source FROM publication';
  $query .= " $constraint;";
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my %publication;
    @publication{@columns} = @$row;
    $publication{registry} = $self->{registry};
    push @publications, G2P::Publication->new(\%publication); 
  }
  return $publications[0];
}

1;
