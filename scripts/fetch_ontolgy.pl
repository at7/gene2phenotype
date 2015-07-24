use strict;
use warnings;

use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous',
  -port => 3337,
);

my $ontology = $registry->get_adaptor( 'Multi', 'Ontology', 'OntologyTerm' );
my $ontology_name = 'GO';
my @terms = @{$ontology->fetch_all_roots($ontology_name)};
foreach my $term (@terms) {
  print $term->name, "\n";
}
