#!/software/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DBI;
use FileHandle;
use Getopt::Long;
use HTTP::Tiny;
use JSON;

use G2P::Registry;

# perl update_publication.pl -registry_file registry

my $config = {};

GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));
my $registry = G2P::Registry->new($config->{registry_file});
my $dbh = $registry->{dbh}; 

main();

sub main {
  my $http = HTTP::Tiny->new();
  my $server = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=';
  
  my $pmids = get_pmids();

  foreach my $pmid (@$pmids) {
    my $response = $http->get($server.$pmid.'&format=json');
    die "Failed !\n" unless $response->{success};
     
    if (length $response->{content}) {
      my $hash = decode_json($response->{content});
      my $result = $hash->{resultList}->{result}[0];
      my $title = $result->{title};
      $title =~ s/'/\\'/g;
      my $journalTitle = $result->{journalTitle};
      my $journalVolume = $result->{journalVolume};
      my $pageInfo = $result->{pageInfo};
      my $pubYear = $result->{pubYear}; 
      my $source = '';
      $source .= "$journalTitle. " if ($journalTitle);
      $source .= "$journalVolume: " if ($journalVolume);
      $source .= "$pageInfo, " if ($pageInfo);
      $source .= "$pubYear." if ($pubYear);
      $dbh->do(qq{UPDATE publication SET title='$title' WHERE pmid=$pmid;}) or die $dbh->errstr;  
      $dbh->do(qq{UPDATE publication SET source='$source' WHERE pmid=$pmid;}) or die $dbh->errstr;  
    }
  }
}


sub get_pmids {
  my @pmids = ();
  my $sth = $dbh->prepare(q{
    SELECT pmid, title, source FROM publication;
  }); 
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($pmid, $title, $source);
  $sth->bind_columns(\($pmid, $title, $source));
  while (my $row = $sth->fetchrow_arrayref()) {
    if ($pmid) {
      push @pmids, $pmid;
    }
  } 
  $sth->finish(); 
  return \@pmids;
}


=begin
{
  'resultList' => {
    'result' => [
      {
        'hasLabsLinks' => 'N',
        'source' => 'MED',
        'dbCrossReferenceList' => {
          'dbName' => [
            'EMBL',
            'OMIM'
          ]
        },
        'issue' => '1',
        'hasReferences' => 'Y',
        'pubYear' => '1984',
        'hasDbCrossReferences' => 'Y',
        'luceneScore' => '107.8565',
        'id' => '6204922',
        'authorString' => 'Snyder FF, Chudley AE, MacLeod PM, Carter RJ, Fung E, Lowe JK.',
        'hasTMAccessionNumbers' => 'N',
        'doi' => '10.1007/bf00270552',
        'pageInfo' => '18-22',
        'journalIssn' => '0340-6717',
        'pubType' => 'journal article; case reports; research support, non-u.s. gov\'t',
        'inEPMC' => 'N',
        'inPMC' => 'N',
        'journalTitle' => 'Hum Genet',
        'journalVolume' => '67',
        'title' => 'Partial deficiency of hypoxanthine-guanine phosphoribosyltransferase with reduced affinity for PP-ribose-P in four related males with gout.',
        'pmid' => '6204922',
        'hasTextMinedTerms' => 'N',
        'citedByCount' => 9
      }
    ]
  },
  'request' => {
    'page' => 1,
    'synonym' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
    'query' => '6204922',
    'resultType' => 'LITE'
  },
  'hitCount' => 1,
  'version' => '4.1'
}
=end
=cut


