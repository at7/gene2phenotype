#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;

# perl update_search.pl -registry_file registry

my $config = {};

GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));

main();

sub main {
  my $registry = G2P::Registry->new($config->{registry_file});
  my $dbh = $registry->{dbh}; 
  $dbh->do(qq{TRUNCATE TABLE search;}) or die $dbh->errstr; 
  $dbh->do(qq{INSERT IGNORE INTO search SELECT gene_symbol FROM genomic_feature WHERE gene_symbol IS NOT NULL;}) or die $dbh->errstr; 
  $dbh->do(qq{INSERT IGNORE INTO search SELECT name FROM disease WHERE name IS NOT NULL;}) or die $dbh->errstr; 
}
