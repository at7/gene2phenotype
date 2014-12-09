use strict;
use warnings;


package G2P::DBSQL::BaseAdaptor;

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my $registry = shift;
  my $dbh = $registry->dbh;
  my $self = bless {
    'registry' => $registry,
    'dbh' => $dbh,
  }, $class;
  
  return $self;
}



1;
