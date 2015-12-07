use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Getopt::Long;

use HTTP::Tiny;
use JSON;
use Data::Dumper;
 
my $http = HTTP::Tiny->new();
 
#my $ext = '/overlap/id/ENSG00000157764?feature=variation&variant_set=ClinVar';
#my $ext = '/overlap/id/ENSG00000157764?feature=transcript';

my $gene = process_get_query('/lookup/id/ENSG00000012048?expand=1');
my $transcripts = $gene->{Transcript};
my ($canonical_transcript) = grep {$_->{is_canonical} == 1} @$transcripts; 
my $transcript_id =  $canonical_transcript->{id};  

my $variants = process_get_query("/overlap/id/$transcript_id?feature=variation&variant_set=ClinVar");

# likely pathogenic, pathogenic
my $pathogenic_variants = {};

foreach my $variant  (@$variants) {
  if (grep {$_ eq 'pathogenic' || $_ eq 'likely pathognic'} @{$variant->{clinical_significance}}) {
    $pathogenic_variants->{$variant->{id}} = 1;
  }
}
my $content = encode_json({'ids' => [keys %$pathogenic_variants], 'canonical' => 1});

my $vep_variants = process_post_query('/vep/human/id', $content);

my $counts = {};

foreach my $variant (@$vep_variants) {
  my $most_severe_consequence = $variant->{most_severe_consequence};
  my $transcript_consequences = $variant->{transcript_consequences};
  my @canonical_transcript_consequences = grep { $_->{transcript_id} eq $transcript_id } @$transcript_consequences;
  print $most_severe_consequence, "\n";
}

#while (my ($key, $value) = each %$variant) {
#  print $key, ' ', $value, "\n";
#}

#foreach my $tv_hash (@canonical_transcript_consequences) {
##  while (my ($key, $value) = each %$tv_hash) {
#    print "$key $value\n";
#  }
#}


#local $Data::Dumper::Terse = 1;
#local $Data::Dumper::Indent = 1;
#print Dumper $vep_variants;
#print "\n";

sub process_get_query {
  my $ext = shift;
  my $server = 'http://rest.ensembl.org';
  my $response = $http->get($server.$ext, {
    headers => { 'Content-type' => 'application/json' }
  });
 
  die "Failed!\n" unless $response->{success};
  my $hash = decode_json($response->{content});
  return $hash;
} 

sub process_post_query {
  my $ext = shift;
  my $content = shift;
  my $server = 'http://rest.ensembl.org';
  my $response = $http->request('POST', $server.$ext, {
    headers => { 
      'Content-type' => 'application/json',
      'Accept' => 'application/json'
    },
    content => $content
  });
  die "Failed!\n" unless $response->{success};
  my $hash = decode_json($response->{content});
  return $hash;
}


=begin
my $config = {};
GetOptions(
  $config,
  ''
) or die "Error: Failed to parse command line arguments\n";

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous',
  -port => 3337,
);

my $gene_adaptor = $registry->get_adaptor('human', 'core', 'gene');
my $vfa = $registry->get_adaptor('human', 'variation', 'variationfeature');
my $source_adaptor = $registry->get_adaptor('human', 'variation', 'source');

my $gene_symbol = 'ZEB2';

my @genes = @{ $gene_adaptor->fetch_all_by_external_name($gene_symbol) };

my @variations_tmpl = ();
my $counts = {};
foreach my $gene (@genes) {
  my $vfs = $vfa->fetch_all_by_Slice_constraint($gene->feature_Slice, "vf.clinical_significance='pathogenic'");
  my $consequence_count = {};

  foreach my $vf (@$vfs) {
    my $assembly = 'GRCh38';
    my $seq_region_name = $vf->seq_region_name;
    my $seq_region_start = $vf->seq_region_start;
    my $seq_region_end = $vf->seq_region_end;

    my $coords = "$seq_region_start-$seq_region_end";

    if ($seq_region_start == $seq_region_end) {
      $coords = $seq_region_start;
    }

    my $var_class = $vf->var_class;
    my $source = $vf->source_name;

    my $allele_string = $vf->allele_string;

    my $consequence = $vf->most_severe_OverlapConsequence();
    my $most_severe_consequence = $consequence->SO_term;
    $counts->{$most_severe_consequence}++;

    my $variant_name = $vf->variation_name;

    my @tvs = @{$vf->get_all_TranscriptVariations()};
    my @filtered_tvs = grep {$_->display_consequence eq $most_severe_consequence} @tvs;
    my @canonical_tvs = grep { $_->transcript->is_canonical == 1 && $_->transcript->stable_id !~ /^LRG/ } @filtered_tvs;
    my $TV;
    if (@canonical_tvs) {
      $TV = $canonical_tvs[0];
    } else {
      $TV = $filtered_tvs[0];
    }
    my $transcript_stable_id = $TV->transcript->stable_id;
    my @tvas = @{$TV->get_all_alternate_TranscriptVariationAlleles};
    foreach my $tva (@tvas) {
      # alternate allele
      my $polyphen_prediction = $tva->polyphen_prediction || '-';
      my $sift_prediction = $tva->sift_prediction || '-';
      my $pep_allele_string = $tva->pep_allele_string || '-';
      print "$seq_region_name:$coords $variant_name $source $var_class $allele_string $most_severe_consequence $transcript_stable_id $pep_allele_string $polyphen_prediction $sift_prediction\n";
    }
  }
}
=end
=cut
