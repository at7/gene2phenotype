use strict;
use warnings;

use FileHandle;
use Getopt::Long;
use G2P::Registry;
use String::Util 'trim';
use Bio::EnsEMBL::Registry;

my $config = {};

GetOptions(
  $config,
  'input_file=s',
  'registry_file=s',
  'username=s',
) or die "Erros: Failed to parse command line arguments\n";

# save cvs as Windows Formatted Text

my $registry = G2P::Registry->new($config->{registry_file});
my $dbh = $registry->{dbh};

my $disease_adaptor = $registry->get_adaptor('disease'); 
my $GFA = $registry->get_adaptor('genomic_feature');
my $GFDA = $registry->get_adaptor('genomic_feature_disease');
my $GFDAA = $registry->get_adaptor('genomic_feature_disease_action');
my $attribute_adaptor = $registry->get_adaptor('attribute');
my $user_adaptor = $registry->get_adaptor('user');
my $phenotype_adaptor = $registry->get_adaptor('phenotype');
my $GFDPhenotypeA = $registry->get_adaptor('genomic_feature_disease_phenotype');
my $GFDPA = $registry->get_adaptor('genomic_feature_disease_publication'); 
my $publication_adaptor = $registry->get_adaptor('publication');

my $ensembl_registry = 'Bio::EnsEMBL::Registry';
$ensembl_registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous'
);

my $gene_adaptor = $ensembl_registry->get_adaptor('human', 'core', 'gene');

# fetch alt_ids
my $alt_ids = {};
my ($term_id, $accession);
my $host = '';
my $dbname = '';
my $user = '';
my $password = '';
my $dbh_ontology = DBI->connect("DBI:mysql:host=$host;database=$dbname", $user, $password, {'RaiseError' => 1});

my $sth = $dbh_ontology->prepare(q{
  SELECT term_id, accession from alt_id;
},  {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
$sth->bind_columns(\($term_id, $accession));
while ($sth->fetch) {
  $alt_ids->{$accession} = $term_id;
}
$sth->finish();

main();

sub main {
  my $disease = {};
  my $G2P = {};
 
  my $unknown_disease_names = {};
  my $allelic_requirements = {};
  my $consequences = {};
  my $DDD_categories = {};
 
  my $panel_id = $attribute_adaptor->attrib_id_for_value('DD');
  die "No panel_id for DD" unless($panel_id);
  
  my $user = $user_adaptor->fetch_by_username($config->{username});
  die "User is not defined for ", $config->{username} unless ($config->{username});
 
  my $fh = FileHandle->new($config->{input_file}, 'r');
 
  while (<$fh>) {
    chomp;
    my @fields = split/\t/;
    if (scalar @fields != 10) {
      print join('---', @fields), "\n";
    }
    my $gene_name = $fields[0];
    my $disease_name = $fields[2];
    $disease_name =~ s/"//g;
    my $uc_disease_name = uc trim $disease_name;
    $disease_name = $uc_disease_name;
    my $disease_mim = $fields[3] || undef;

    my $disease = $disease_adaptor->fetch_by_name($disease_name);
    if (!$disease) {
      print "Create new disease object for $disease_name\n";
      $disease = G2P::Disease->new({
        name => $disease_name,
        mim => $disease_mim, 
      });
      $disease = $disease_adaptor->store($disease);
    }

    my $genomic_feature = $GFA->fetch_by_gene_symbol($gene_name);
    if (!$genomic_feature) {
      my $genes = $gene_adaptor->fetch_all_by_external_name($gene_name);
      my $core_gene_names = {};
      foreach my $gene (@$genes) {
        my $external_name = $gene->external_name;
        my $stable_id = $gene->stable_id;
        next if ($stable_id =~ /^LRG/);
        $core_gene_names->{$external_name} = 1;
      }
      if (scalar keys %$core_gene_names == 1) {
        my @core_genes = keys %$core_gene_names;
        my $core_gene = $core_genes[0];
        print $core_gene, "\n";
        $genomic_feature = $GFA->fetch_by_gene_symbol($core_gene);
        if (!$genomic_feature) {
          print "No genomic_feature for $core_gene\n";
        } else {
          my $synonyms = $genomic_feature->synonyms();
          my $gfd_id = $genomic_feature->dbID;
          if (length $synonyms == 0) {
            print "no synonyms\n";
            $dbh->do(qq{INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($gfd_id, '$gene_name');}) or die $dbh->errstr; 
          } else {
            print "Synonyms $synonyms\n";
          }
        }
      } else {
        die "Couldn't find gene for $gene_name\n";
      } 
    }

    if (!$genomic_feature && !$disease) {
      die "Cannot create new gene-disease pair for $gene_name and $disease_name\n";
    }
    my $DDD_category = $fields[4];
    $DDD_category =~ s/Confirmed/confirmed/g;
    $DDD_category =~ s/Gene/gene/g;
    $DDD_category =~ s/Possible/possible/g;
    $DDD_category =~ s/Both/both/g;
    $DDD_category =~ s/Probable/probable/g;
    my $DDD_category_attrib = $attribute_adaptor->attrib_id_for_value($DDD_category);
    die "No attrib_id for $DDD_category" unless($DDD_category_attrib);
    my $GFD = $GFDA->fetch_by_GenomicFeature_Disease_panel_id($genomic_feature, $disease, $panel_id);
    if (!$GFD) {
      print "create new GFD\n";
      $GFD = G2P::GenomicFeatureDisease->new({
        genomic_feature_id => $genomic_feature->dbID,
        disease_id => $disease->dbID,
        DDD_category_attrib => $DDD_category_attrib,
        panel_attrib => $panel_id,
        registry => $registry,
      });
      $GFD = $GFDA->store($GFD, $user);
    }  

    my $allelic_requirement = lcfirst($fields[5]);
    my $allelic_requirement_attrib = $attribute_adaptor->attrib_id_for_value($allelic_requirement);
    die "No attrib_id for $allelic_requirement" unless ($allelic_requirement_attrib);
    my $consequence = lcfirst($fields[6]);
    my $consequence_attrib = $attribute_adaptor->attrib_id_for_value($consequence);
    die "No attrib_id for $consequence" unless ($consequence_attrib);

#    my $genomic_feature_disease_action = G2P::GenomicFeatureDiseaseAction->new({
#      genomic_feature_disease_id => $GFD->dbID,
#      allelic_requirement_attrib => $allelic_requirement_attrib,
#      mutation_consequence_attrib => $consequence_attrib,
#    });
#    $GFDAA->store($genomic_feature_disease_action, $user);


    my $phenotypes = $fields[7];
    my @phenotypes = split(/\s;|;\s+/, $fields[7]) if ($fields[7]);

    # Phenotype 
    foreach my $stable_id (@phenotypes) {
      my $phenotype = $phenotype_adaptor->fetch_by_stable_id($stable_id);
      if (!$phenotype) {
        my $alt_id = $alt_ids->{$stable_id};
        $phenotype = $phenotype_adaptor->fetch_by_dbID($alt_id);
        if (!$phenotype) {
          die "No phenotype object for $stable_id\n";
        }
      }
#      my $GFD_phenotype = G2P::GenomicFeatureDiseasePhenotype->new({
#        genomic_feature_disease_id => $GFD->dbID, 
#        phenotype_id => $phenotype->dbID,
#        registry => $registry,
#      });
#      $GFDPhenotypeA->store($GFD_phenotype);
    }
    my $pmid_ids_field = trim $fields[9];
    my @pmid_ids = split(/\s;|;\s+/, $pmid_ids_field);
    foreach my $pmid (@pmid_ids) {
      my $publication = $publication_adaptor->fetch_by_PMID($pmid);
      if (!$publication) {
        $publication = G2P::Publication->new({
          pmid => $pmid,
        });
        $publication = $publication_adaptor->store($publication);
      }
#      my $GFD_publication = G2P::GenomicFeatureDiseasePublication->new({
#        genomic_feature_disease_id => $GFD->dbID, 
#        publication_id => $publication->dbID,
#        registry => $registry,
#      });
#      $GFDPA->store($GFD_publication);
    }

  }
  $fh->close();
}
