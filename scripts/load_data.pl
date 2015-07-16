#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;
use G2P::Phenotype;
use G2P::Organ;

use Text::CSV;
use String::Util 'trim';

my $config = {};

GetOptions(
  $config,
  'input_file=s',
  'registry_file_old=s',
  'registry_file_new=s',
  'user_name=s',
) or die "Erros: Failed to parse command line arguments\n";

die('An input file is required (--input_file)') unless (defined($config->{input_file}));
die('A registry file with connection details for the old database is required (--registry_file_old)') unless (defined($config->{registry_file_old}));
die('A registry file with connection details for the new database is required (--registry_file_new)') unless (defined($config->{registry_file_new}));

my $user_name = $config->{user_name};

my $registry_old = G2P::Registry->new($config->{registry_file_old});
my $dbh_old = $registry_old->{dbh};

my $registry_new = G2P::Registry->new($config->{registry_file_new});
my $dbh_new = $registry_new->{dbh};

my $known_disease_names = {};
my $known_disease_mims = {};

get_known_disease_data();

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
    if (scalar @fields > 10) {
      print join('---', @fields), "\n";
    }
    my $disease_id = $fields[0];
    my $disease_name = $fields[1]; 
    if ($disease_name) {
      $disease_name =~ s/"//g;
      my $uc_disease_name = uc trim $disease_name;
      $disease_name = $uc_disease_name;
    } 
    my @phenotypes = ();
    @phenotypes = split(/\s;|;\s+/, $fields[2]) if ($fields[2]);
    my $allelic_requirement = trim $fields[3];

    $allelic_requirement = lcfirst($allelic_requirement);
    $allelic_requirements->{$allelic_requirement} = 1;
    my $consequence = trim $fields[4];
    if ($consequence eq "5' or 3'UTR mutation") {
      $consequence = '5_prime or 3_prime UTR mutation';
    } else {
      $consequence = lcfirst($consequence);
    }
    $consequences->{$consequence} = 1;
    my $omim_disease_id = $fields[5];
    my $tissue = trim $fields[6];
    my @organs = ();
    @organs = sort split(/\s+;|;\s+/, $tissue) if ($tissue);
    my @pmid_ids = ();
    @pmid_ids = split(/\s;|;\s+/, $fields[7]) if ($fields[7]);
    my $DDD_category = trim $fields[8];
    $DDD_category =~ s/Confirmed/confirmed/g;
    $DDD_category =~ s/Gene/gene/g;
    $DDD_category =~ s/Possible/possible/g;
    $DDD_category =~ s/Both/both/g;
    $DDD_category =~ s/Probable/probable/g;
    my $gene_name = trim $fields[9]; 

    if ($disease_name) {
      if (!$omim_disease_id) {
        $omim_disease_id = $known_disease_mims->{$disease_name} || undef;
      }
    } else {
      print 'Missing disease name ',  $disease_id, ' ', $omim_disease_id, "\n";
    }

    if (!$gene_name) {
      print 'Missing gene name ', $disease_id, "\n";
    }
   
    if ($disease_name && $gene_name) { 
      my $key = "$disease_name\t$gene_name";
      $G2P->{$key}->{omim_disease_id} = $omim_disease_id;
      if ($allelic_requirement && $consequence) {
        push @{$G2P->{$key}->{GFDA}}, {'allelic_requirement' => $allelic_requirement, 'consequence' => $consequence};
    }
      $G2P->{$key}->{DDD_category}->{$DDD_category} = 1;
      foreach my $organ (@organs) {
        $G2P->{$key}->{organ}->{$organ} = 1;
      }
      foreach my $pmid (@pmid_ids) {
        $G2P->{$key}->{pmid}->{$pmid} = 1;
      }
      foreach my $phenotype (@phenotypes) {
        $G2P->{$key}->{phenotype}->{$phenotype} = 1;
      }  
    }
  }

  $fh->close();

  import_data($G2P);  

}

sub import_data {
  my $G2P = shift;

  # truncate:
  my @tables = qw/genomic_feature_disease genomic_feature_disease_action genomic_feature_disease_log genomic_feature_disease_action_log genomic_feature_disease_organ genomic_feature_disease_phenotype genomic_feature_disease_publication/;

  my $dbh = $registry_new->{dbh};
  foreach my $table (@tables) {
    $dbh->do(qq{TRUNCATE TABLE $table;}) or die $dbh->errstr; 
  }
  my $disease_adaptor = $registry_new->get_adaptor('disease'); 
  my $GFA   = $registry_new->get_adaptor('genomic_feature');
  my $GFDA  = $registry_new->get_adaptor('genomic_feature_disease'); 
  my $GFDPA = $registry_new->get_adaptor('genomic_feature_disease_publication'); 
  my $GFDOA = $registry_new->get_adaptor('genomic_feature_disease_organ'); 
  my $GFDPhenotypeA = $registry_new->get_adaptor('genomic_feature_disease_phenotype'); 
  my $GFDAA = $registry_new->get_adaptor('genomic_feature_disease_action');
  my $attribute_adaptor = $registry_new->get_adaptor('attribute');
  my $user_adaptor = $registry_new->get_adaptor('user');
  my $publication_adaptor = $registry_new->get_adaptor('publication');
  my $phenotype_adaptor = $registry_new->get_adaptor('phenotype');
  my $organ_adaptor = $registry_new->get_adaptor('organ');


  my $user = $user_adaptor->fetch_by_username($user_name);
  my $allelic_requirements_attribs = $attribute_adaptor->get_attribs_by_type_value('allelic_requirement'); 
  my $mutation_consequence_attribs = $attribute_adaptor->get_attribs_by_type_value('mutation_consequence');
  my $ddd_category_attribs = $attribute_adaptor->get_attribs_by_type_value('DDD_Category');

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

    my $GF = $GFA->fetch_by_gene_symbol($gene_name);
    if (!$GF) {
      die "No GF for $gene_name\n";
    } 

    my $GFD = $GFDA->fetch_by_GenomicFeature_Disease($GF, $disease);
    my @DDD_categories = keys %{$G2P->{$key}->{DDD_category}};
    if (scalar @DDD_categories > 1) {
      print $gene_name, "\n";
    }
    my $DDD_category_attrib = undef; 
    if ($DDD_categories[0]) {
      $DDD_category_attrib = $ddd_category_attribs->{$DDD_categories[0]};
      if (!$DDD_category_attrib) {
        print $DDD_categories[0], ' ', $gene_name, "\n";
      }
    }   

    if (!$GFD) {
      $GFD = G2P::GenomicFeatureDisease->new({
        genomic_feature_id => $GF->dbID,
        disease_id => $disease->dbID,
        DDD_category_attrib => $DDD_category_attrib,
      });
      $GFD = $GFDA->store($GFD, $user);
    }  

    foreach my $gfda_hash (@{$G2P->{$key}->{GFDA}}) {
      my $allelic_requirement = $gfda_hash->{allelic_requirement};
      my $consequence = $gfda_hash->{consequence};
      my $allelic_requirement_attrib = $allelic_requirements_attribs->{$allelic_requirement};
      my $mutation_consequence_attrib = $mutation_consequence_attribs->{$consequence};
      my $genomic_feature_disease_action = G2P::GenomicFeatureDiseaseAction->new({
        genomic_feature_disease_id => $GFD->dbID,
        allelic_requirement_attrib => $allelic_requirement_attrib,
        mutation_consequence_attrib => $mutation_consequence_attrib,
      });
      $GFDAA->store($genomic_feature_disease_action, $user);
    }

    # Publication
    foreach my $pmid (keys %{$G2P->{$key}->{pmid}}) {
     my $publication = $publication_adaptor->fetch_by_PMID($pmid);
      if (!$publication) {
        $publication = G2P::Publication->new({
          pmid => $pmid,
        });
        $publication = $publication_adaptor->store($publication);
      }
      my $GFD_publication = G2P::GenomicFeatureDiseasePublication->new({
        genomic_feature_disease_id => $GFD->dbID, 
        publication_id => $publication->dbID,
        registry => $registry_new,
      });
    $GFDPA->store($GFD_publication);
    }

    # Phenotype 
    foreach my $stable_id (keys %{$G2P->{$key}->{phenotype}}) {
      my $phenotype = $phenotype_adaptor->fetch_by_stable_id($stable_id);
      if (!$phenotype) {
        $phenotype = G2P::Phenotype->new({
          stable_id => $stable_id,
        });
        $phenotype = $phenotype_adaptor->store($phenotype);
      }
      my $GFD_phenotype = G2P::GenomicFeatureDiseasePhenotype->new({
        genomic_feature_disease_id => $GFD->dbID, 
        phenotype_id => $phenotype->dbID,
        registry => $registry_new,
      });
      $GFDPhenotypeA->store($GFD_phenotype);
    }
    # Organ
    foreach my $name (keys %{$G2P->{$key}->{organ}}) {
      my $organ = $organ_adaptor->fetch_by_name($name);
      if (!$organ) {
        $organ = G2P::Organ->new({
          name => $name,
        });
        $organ = $organ_adaptor->store($organ);
      }
      my $GFD_organ = G2P::GenomicFeatureDiseaseOrgan->new({
        genomic_feature_disease_id => $GFD->dbID, 
        organ_id => $organ->dbID,
        registry => $registry_new,
      });
      $GFDOA->store($GFD_organ);
    }
  }
}

sub get_known_disease_data {
  my $sth = $dbh_old->prepare(q{
    SELECT disease_id, name, mim  FROM disease;
  }, {mysql_use_result => 1});
  $sth->execute() or die $dbh_old->errstr;
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

