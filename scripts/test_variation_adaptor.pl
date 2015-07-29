#!/software/bin/perl

use strict;
use warnings;

use Getopt::Long;
use G2P::Registry;


my $config = {};

GetOptions(
  $config,
  'registry_file=s',
) or die "Erros: Failed to parse command line arguments\n";


my $registry = G2P::Registry->new($config->{registry_file});


my $variation_adaptor = $registry->get_adaptor('variation');
my $GFDA = $registry->get_adaptor('genomic_feature_disease');

my $GFD = $GFDA->fetch_by_dbID(1954);

my $variations = $variation_adaptor->fetch_all_by_genomic_feature_id_disease_id($GFD->genomic_feature_id, $GFD->disease_id);
foreach my $variation (@$variations) {
    my $mutation    = $variation->mutation;
    my $consequence = $variation->consequence;
    my $publication = $variation->get_Publication;
    print $mutation, "\n";
    my ($title, $pmid);
    if ($publication) {
      $title = $publication->title;
      $pmid = $publication->pmid;
    }
    my $variation_synonyms = $variation->get_all_synonyms_order_by_source;
  }
