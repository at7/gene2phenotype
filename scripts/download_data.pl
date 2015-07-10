#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;
use Text::CSV;

use G2P::Registry;

my $config = {};

GetOptions(
  $config,
  'csv_file=s',
  'registry=s',
) or die "Erros: Failed to parse command line arguments\n";

die('A name for the output file is required (--csv_file)') unless (defined($config->{csv_file}));
die('A registry file with database connection details is required (--registry)') unless (defined($config->{registry}));

main();

sub main {
  my $csv_file = $config->{csv_file};

  my $registry = G2P::Registry->new($config->{registry});
  
  my $GFD_adaptor = $registry->get_adaptor('genomic_feature_disease');

  my $GFDs = $GFD_adaptor->fetch_all();

  my $csv = Text::CSV->new ( { binary => 1, eol => "\r\n" } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
  open my $fh, ">:encoding(utf8)", "$csv_file" or die "$csv_file: $!";
  $csv->eol ("\r\n");  

  foreach my $GFD (@$GFDs) {
  # Header: Gene_name Gene_mim Disease_name Disease_mim DDD_category Allelic_requirement Mutation_consequence Phenotypes Organs PMIDs
    my $gene_symbol = $GFD->get_GenomicFeature()->gene_symbol || 'No gene symbol'; 
    my $gene_mim = $GFD->get_GenomicFeature()->mim || 'No gene mim'; 
    my $disease_name = $GFD->get_Disease()->name || 'No disease name';
    my $disease_mim = $GFD->get_Disease()->mim || 'No disease mim';
    my $DDD_category = $GFD->DDD_category() || 'No DDD category';
    my $phenotypes = join(';', map {$_->get_Phenotype->stable_id} @{$GFD->get_all_GFDPhenotypes});
    my $organs = join(';', map {$_->get_Organ->name} @{$GFD->get_all_GFDOrgans});
    my $pmids = join(';', map {$_->get_Publication->pmid} @{$GFD->get_all_GFDPublications});
    my $GFDAs = $GFD->get_all_GenomicFeatureDiseaseActions();
    foreach my $GFDA (@$GFDAs) {
      my $allelic_requirement = $GFDA->allelic_requirement;
      my $mutation_consequence = $GFDA->mutation_consequence;
      my @row = ($gene_symbol, $gene_mim, $disease_name, $disease_mim, $DDD_category, $allelic_requirement, $mutation_consequence, $phenotypes, $organs, $pmids);
      $csv->print ($fh, \@row);
    }
  }
  close $fh or die "$csv: $!";
  
  system("gzip $csv_file");
}

