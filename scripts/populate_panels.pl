use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use G2P::Registry;

# panels: 
# cardiac -- Heart/Cardiovasculature
# dd
# ear -- Ear
# eye -- Eye
# skin -- Skin 


my $config = {};

GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));


my $registry = G2P::Registry->new($config->{registry_file});

my $GFD_organ_adaptor = $registry->get_adaptor('genomic_feature_disease_organ');
my $organ_adaptor = $registry->get_adaptor('organ');


my @organ_names = qw{Heart/Cardiovasculature Ear Eye Skin};

foreach my $organ_name (@organ_names) {
  my $organ = $organ_adaptor->fetch_by_name($organ_name);   
  print $organ->name, "\n";
}

my $GFD_organs = $GFD_organ_adaptor->fetch_all();

print scalar @$GFD_organs, "\n";

my $organ_counts = {};

foreach my $GFD_organ (@$GFD_organs) {
  my $organ = $GFD_organ->get_Organ->name;
  $organ_counts->{$organ}++;
}

foreach my $organ (sort { $organ_counts->{$b} <=> $organ_counts->{$a} } keys %$organ_counts) {
  print $organ, ' ', $organ_counts->{$organ}, "\n";
}



