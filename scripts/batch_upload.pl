use strict;
use warnings;

use FileHandle;
use Getopt::Long;
use G2P::Registry;
use String::Util 'trim';

my $config = {};

GetOptions(
  $config,
  'input_file=s',
  'registry_file=s',
  'user_name=s',
) or die "Erros: Failed to parse command line arguments\n";


# save cvs as Windows Formatted Text


my $registry = G2P::Registry->new($config->{registry_file});

my $disease_adaptor = $registry->get_adaptor('disease'); 

main();

sub main {
  my $disease = {};
  my $G2P = {};
 
  my $unknown_disease_names = {};
  my $allelic_requirements = {};
  my $consequences = {};
  my $DDD_categories = {};
  
  my $fh = FileHandle->new($config->{input_file}, 'r');
 
  while (<$fh>) {
    chomp;
    my @fields = split/\t/;
    if (scalar @fields != 10) {
      print join('---', @fields), "\n";
    }
    my $gene_name = $fields[0];
#    print $gene_name, "\n";
    my $disease_name = $fields[2];
    $disease_name =~ s/"//g;
    my $uc_disease_name = uc trim $disease_name;
    $disease_name = $uc_disease_name;
    my $disease = $disease_adaptor->fetch_by_name($disease_name);
#    print "$disease_name\n" if ($disease);

    my $disease_mim = $fields[3];
    if ($disease_mim) {
      my $disease = $disease_adaptor->fetch_by_mim($disease_mim);
      print "$disease_name\n" if ($disease);
    }
  
#    print $disease_name, "\n";
    my $DDD_category = $fields[4];
    $DDD_category =~ s/Confirmed/confirmed/g;
    $DDD_category =~ s/Gene/gene/g;
    $DDD_category =~ s/Possible/possible/g;
    $DDD_category =~ s/Both/both/g;
    $DDD_category =~ s/Probable/probable/g;
#    print $DDD_category, "\n";
    my $allelic_requirement = $fields[5];
    $allelic_requirement = lcfirst($allelic_requirement);
#    print $allelic_requirement, "\n";
    my $consequence = $fields[6];
    my $phenotypes = $fields[7];
    my @phenotypes = split(/\s;|;\s+/, $fields[7]) if ($fields[7]);
    my $pmids = $fields[9];

#    print $gene_name, "\n";
#    if (@phenotypes) {
#      print join(',', @phenotypes), "\n";
#    }
#    print scalar @fields, "\n";
  }
  $fh->close();

}
