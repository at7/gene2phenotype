#!/software/bin/perl
use strict;
use warnings;

use DBI;
use Getopt::Long;

use G2P::Registry;
use Bio::OntologyIO;
use G2P::Phenotype;

my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'obo_file=s',
) or die "Erros: Failed to parse command line arguments\n";

die('A registry file with connection details is required (--registry_file)') unless (defined($config->{registry_file}));
die('An obo file is required (--obo_file)') unless (defined($config->{obo_file}));


my $parser = Bio::OntologyIO->new( -format => "obo", -file => $config->{obo_file});

my $hpo_terms = {}; 
while (my $ont = $parser->next_ontology()) {
  my @terms = $ont->get_all_terms;
  foreach my $term (@terms) {
    my $stable_id = $term->identifier;
    my $name = $term->name;
    $hpo_terms->{$stable_id} = $name;
  } 
}

my $registry = G2P::Registry->new($config->{registry_file});
my $phenotype_adaptor = $registry->get_adaptor('phenotype');

my $phenotypes = $phenotype_adaptor->fetch_all();

my $in_db = {};
foreach my $phenotype (@$phenotypes) {
  if (!$phenotype->name) {
    $phenotype->name($hpo_terms->{$phenotype->stable_id});
    $phenotype_adaptor->update($phenotype);
  }
  $in_db->{$phenotype->stable_id} = 1;
}

foreach my $stable_id (keys %$hpo_terms) {
  if (!$in_db->{$stable_id}) {
    my $name = $hpo_terms->{$stable_id};
    my $phenotype = G2P::Phenotype->new({
      stable_id => $stable_id,
      name => $name,
    });
    $phenotype_adaptor->store($phenotype); 
  }
}
