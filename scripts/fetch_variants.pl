use strict;
use warnings;


use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous',
  -port => 3337,
);

my $gene_adaptor = $registry->get_adaptor('human', 'core', 'gene');
my $vfa = $registry->get_adaptor('human', 'variation', 'variationfeature');
my $source_adaptor = $registry->get_adaptor('human', 'variation', 'source');

my $source = $source_adaptor->fetch_by_name('ClinVar');
my $source_id = $source->dbID;
print $source_id, "\n";

 
my @genes = @{ $gene_adaptor->fetch_all_by_external_name('AAAS') };

foreach my $gene (@genes) {
  my $vfs = $vfa->fetch_all_by_Slice_constraint($gene->feature_Slice, "vf.clinical_significance IS NOT NULL");
  my $consequence_count = {};
  foreach my $vf (@$vfs) {
    my $tvs = $vf->get_all_TranscriptVariations(); 
    foreach my $tv (@$tvs) {
      print join ",", @{$tv->consequence_type}, "\n";
    }
  } 
} 

