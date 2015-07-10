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

  my $csv = Text::CSV->new ( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
  
  open my $fh, ">:encoding(utf8)", "$csv_file" or die "$csv_file: $!";

  foreach my $GFD (@$GFDs) {
  # Header: Gene_name Gene_mim Disease_name Disease_mim DDD_category Allelic_requirement Mutation_consequence Phenotypes Organs PMIDs
    my @row = ();
    my $gene_symbol = $GFD->get_GenomicFeature()->gene_symbol || 'No gene symbol'; 
    my $gene_mim = 
    my $disease_name = $GFD->get_Disease()->name;
    my $disease_mim = ;
    my $DDD_category = $GFD->DDD_category() || 'No DDD category';
    my $phenotypes = join(',', map {$_->stable_id} @{$GFD->get_all_GFDPhenotypes});
    my $organs = join(',', map {$_->name} @{$GFD->get_all_GFDOrgans});
#get_all_GFDPublications
    $csv->print ($fh, \@row);
  }
  close $fh or die "$csv: $!";

}

