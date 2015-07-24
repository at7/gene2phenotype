use strict;
use warnings;

use JSON;
use Data::Dumper;
use HTTP::Tiny;
use String::Util 'trim';
use DBI;
use FileHandle;

my $http = HTTP::Tiny->new();
my $api_key = '';

my $dir = '';

my $gene_mims = fetch_gene_mims();
export_variants($gene_mims);

sub fetch_gene_mims {
  return {
    190181 => 1,
  };
}

sub export_variants {
  my $gene_mims = shift;
  print "export_variants\n";
  my $fh = FileHandle->new("$dir/gene_variants_24_07.txt", 'w');
  foreach my $gene_mim (keys %$gene_mims) {
    print $gene_mim, "\n";
    my $response = run_query($gene_mim, 'gene_mim_variants');
    my $hash = decode_json($response->{content});
   print Dumper($hash); 
    my @allelic_variants = @{$hash->{omim}->{allelicVariantLists}};
    die "More than one element in allelic_variants " if (scalar @allelic_variants > 1);
    foreach (@{$allelic_variants[0]->{allelicVariantList}}) {
      my $allelic_variant = $_->{allelicVariant};
      my $mutations = $allelic_variant->{mutations} || '\N';
      my $clinvarAccessions = $allelic_variant->{clinvarAccessions} || '\N';
      my $dbSNPs = $allelic_variant->{dbSnps} || '\N';

      print $fh join("\t", $gene_mim, $mutations, $clinvarAccessions, $dbSNPs), "\n";
    }
  }
  $fh->close();
}


sub run_query {
  my $parameter = shift;
  my $query_type = shift;
  my $server = 'http://api.omim.org/api';
  my $exts = {
    'phenotype_mim'                => '/entry?mimNumber=PARAMETER&format=json',
    'phenotype_mim_include_all'    => '/entry?mimNumber=PARAMETER&include=all&format=json',
    'phenotype_mim_include_text'   => '/entry?mimNumber=PARAMETER&include=text&format=json',
    'reference_list'               => '/entry?mimNumber=PARAMETER&include=referenceList&format=json',
    'phenotype_mim_external_links' => '/entry?mimNumber=PARAMETER&include=externalLinks&format=json',
    'gene_mim'                     => '/entry?mimNumber=PARAMETER&format=json',
    'gene_mim_external_links'      => '/entry?mimNumber=PARAMETER&include=externalLinks&format=json',
    'gene_mim_variants'            => '/entry/allelicVariantList?mimNumber=PARAMETER&format=json',
    'gene_mim_phenotypes'          => '/entry?mimNumber=PARAMETER&include=geneMap&format=json',
    'search_with_gene_symbol'      => '/entry/search?search=PARAMETER&format=json',
  };

  my $ext = $exts->{$query_type};
  die "No match for query type: $query_type" unless($ext);
  $ext =~ s/PARAMETER/$parameter/;
  my $response = $http->get($server.$ext, {
    headers => { 'ApiKey' => $api_key, 'Content-type' => 'application/json' }
  });
  die "Failed!\n" unless $response->{success};
  return $response;
}

sub print_response {
  my $response = shift;
  if (length $response->{content}) {
    my $hash = decode_json($response->{content});
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    print Dumper $hash;
    print "\n";
  }
}

