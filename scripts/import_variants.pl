#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;

my $config = {};

GetOptions(
  $config,
  'registry_file=s',
) or die "Erros: Failed to parse command line arguments\n";


my $registry = G2P::Registry->new($config->{registry_file});
my $disease_adaptor = $registry->get_adaptor('disease');
my $GFA = $registry->get_adaptor('genomic_feature');
my $publication_adaptor = $registry->get_adaptor('publication');
my $variation_adaptor = $registry->get_adaptor('variation'); 

my $host = '';
my $dbname = '';
my $user = '';
my $password = '';
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$dbname", $user, $password, {'RaiseError' => 1});

my ($var_id, $gene_symbol, $GFD_id, $disease_name, $disease_mim, $disease_id, $pmid, $publication_id, $mutation, $consequence);
my $sth = $dbh->prepare(q{
  select v.variation_id, gf.gene_symbol, v.genomic_feature_id , d.name, d.mim, v.disease_id, p.pmid, v.publication_id, v.mutation, v.consequence
  from publication p, disease d, genomic_feature gf, variation v
  where v.genomic_feature_id = gf.genomic_feature_id
  and v.disease_id = d.disease_id
  and v.publication_id = p.publication_id;
},  {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
$sth->bind_columns(\($var_id, $gene_symbol, $GFD_id, $disease_name, $disease_mim, $disease_id, $pmid, $publication_id, $mutation, $consequence));

my ($GF, $disease, $publication);
while ($sth->fetch) {
  
  if ($disease_name) {
    $disease = $disease_adaptor->fetch_by_name($disease_name);
    if (!$disease) {
      $disease = G2P::Disease->new({
        name => $disease_name,
      });
      $disease = $disease_adaptor->store($disease);
    } 
  } elsif ($disease_mim) {
    $disease = $disease_adaptor->fetch_by_mim($disease_mim);
    if (!$disease) {
      $disease = G2P::Disease->new({
        mim => $disease_mim,
      });
      $disease = $disease_adaptor->store($disease);
    } 
  } else {
    print "Cannot fetch disease $disease_id\n";
  }

  if ($gene_symbol) {
    $GF = $GFA->fetch_by_gene_symbol($gene_symbol); 
  } else {
    print "Cannot fetch gene $gene_symbol\n";
  }  

  if ($pmid) {
    $publication = $publication_adaptor->fetch_by_PMID($pmid);
  } else {
    print "Cannot fetch publication $publication_id\n";
  }

  if ($disease && $GF && $publication) {
    my $synonyms = get_synonyms($var_id);
    my $variation = G2P::Variation->new({
      genomic_feature_id => $GF->dbID,
      disease_id => $disease->dbID,
      publication_id => ($publication) ? $publication->dbID : undef,
      mutation => $mutation,
      consequence => $consequence, 
      synonyms => $synonyms,  
    });
    
  $variation_adaptor->store($variation);

  } else {
    print "Data missing\n";
  }


}
$sth->finish();

sub get_synonyms {
  my $variation_id = shift;
  my $synonyms = {};
  my ($name, $source);
  my $dbh2 = DBI->connect("DBI:mysql:host=$host;database=$dbname", $user, $password, {'RaiseError' => 1});

  my $sth2 = $dbh2->prepare(q{
    SELECT name, source FROM variation_synonym WHERE variation_id=?;
  },  {mysql_use_result => 1});
  $sth2->execute($variation_id) or die $dbh->errstr;
  $sth2->bind_columns(\($name, $source));
  while ($sth2->fetch) {
    $synonyms->{$source}->{$name} = 1;  
  }
  $sth2->finish();
  return $synonyms;
}


