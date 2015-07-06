#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;

use Text::CSV;
use String::Util 'trim';

my $config = {};

GetOptions(
  $config,
  'input_file=s',
  'registry_file_old=s',
  'registry_file_new=s',
) or die "Erros: Failed to parse command line arguments\n";

die('An input file is required (--input_file)') unless (defined($config->{input_file}));

my $registry_old = G2P::Registry->new($config->{registry_file_old});
my $dbh_old = $registry_old->{dbh};

my $registry_new = G2P::Registry->new($config->{registry_file_new});
my $dbh_new = $registry_new->{dbh};

my $known_disease_names = {};
my $known_disease_mims = {};

get_known_disease_data();

main();

sub main {

  my $csv = Text::CSV->new ({
    binary    => 1,
    auto_diag => 1,
    sep_char  => ',',    # not really needed as this is the default
  });
  my $file = $config->{input_file};
  open(my $data, '<:encoding(utf8)', $file) or die "Could not open '$file' $!\n";

  my $disease = {};
  my $G2P = {};
 
  my $unknown_disease_names = {};
  my $allelic_requirements = {};
  my $consequences = {};
  my $DDD_categories = {};
 
  while (my $fields = $csv->getline($data)) {
    my $disease_id = $fields->[0];
    my $disease_name = $fields->[1];
    my $uc_disease_name = uc trim $disease_name;
    my @phenotypes = split(/\s;|;\s+/, $fields->[2]);
    my $allelic_requirement = $fields->[3];
    my $consequence = $fields->[4];
    my $omim_disease_id = $fields->[5];
    my $tissue = $fields->[6];
    my @organs = sort split(/\s+;|;\s+/, $tissue);
    my @pmid_ids = split(/\s;|;\s+/, $fields->[7]);
    my $DDD_category = $fields->[8];
    my $gene_name = $fields->[9]; 

    if ($uc_disease_name) {
      if (!$omim_disease_id) {
        $omim_disease_id = $known_disease_mims->{$uc_disease_name} || undef;
      }
    } else {
      print 'Missing disease name ',  $disease_id, ' ', $omim_disease_id, "\n";
    }

    if (!$gene_name) {
      print 'Missing gene name ', $disease_id, "\n";
    }
   
    if ($uc_disease_name && $gene_name) { 
      my $key = "$uc_disease_name\t$gene_name";
      $G2P->{$key}->{omim_disease_id} = $omim_disease_id;
      push @{$G2P->{$key}->{GFDA}}, {'allelic_requirement' => $allelic_requirement, 'consequence' => $consequence};
      $G2P->{$key}->{DDD_category}->{$DDD_category} = 1;
      foreach my $organ (@organs) {
        $G2P->{$key}->{organ}->{$organ} = 1;
      }
      foreach my $pmid (@pmid_ids) {
        $G2P->{$key}->{pmid} = $pmid;
      }
      foreach my $phenotype (@phenotypes) {
        $G2P->{$key}->{phenotype}->{$phenotype} = 1;
      }  
    }
  }
  close $data;

  import_data($G2P);  

}

sub import_data {
  my $G2P = shift;

  my $disease_adaptor = $registry_new->get_adaptor('disease'); 
  my $GFDA = $registry_new->get_adaptor('genomic_feature_disease'); 
  my $GFDAA = $registry_new->get_adaptor('genomic_feature_disease_action');
  my $attribute_adaptor = $registry_new->get_adaptor('attribute');
 
  my $allelic_requirements_attribs = $attribute_adaptor->get_attribs_by_type_value('allelic_requirement'); 
  my $mutation_consequence_attribs = $attribute_adaptor->get_attribs_by_type_value('mutation_consequence');

  foreach my $key (keys %$G2P) {
    my ($disease_name, $gene_name) = split(/\t/, $key);
    my $omim_disease_id = $G2P->{$key}->{omim_disease_id};
    my $disease = $disease_adaptor->fetch_by_name($disease_name);
    if (!$disease) {
      $disease = G2P::Disease->new({
        name => $disease_name,
        mim => $omim_disease_id, 
      });
      $disease = $disease_adaptor->store($disease);
    } 
    
  }
    



}



sub get_known_disease_data {
  my $sth = $dbh_old->prepare(q{
    SELECT disease_id, name, mim  FROM disease;
  }, {mysql_use_result => 1});
  $sth->execute() or die $dbh->errstr;
  my ($disease_id, $name, $mim);
  $sth->bind_columns(\($disease_id, $name, $mim));
  while ($sth->fetch) {
    if ($name) {
      $known_disease_names->{$name} = $mim || 1;    
    }
    if ($mim) {
      $known_disease_mims->{$mim} = $name || 1;
    }              

  }
  $sth->finish();
}





