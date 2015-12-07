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

my $GFD_adaptor = $registry->get_adaptor('genomic_feature_disease');
my $GFD_phenotype_adaptor = $registry->get_adaptor('genomic_feature_disease_phenotype');
my $GFD_publication_adaptor = $registry->get_adaptor('genomic_feature_disease_publication');
my $GFD_organ_adaptor = $registry->get_adaptor('genomic_feature_disease_organ');
my $GFD_action_adaptor = $registry->get_adaptor('genomic_feature_disease_action');
my $organ_adaptor = $registry->get_adaptor('organ');
my $attrib_adaptor = $registry->get_adaptor('attribute');
my $user_adaptor = $registry->get_adaptor('user');

my $user = $user_adaptor->fetch_by_username('anja_thormann');

print $user->username, "\n";

my $g2p_panels = {
  'Cardiac' => ['Heart/Cardiovasculature/Lymphatic', 'Heart/Cardiovasculature'],
  'Ear' => ['Ear'],
  'Eye' => ['Eye'],
  'Skin' => ['Skin'],
};

my $panel_2_GFD = {};

foreach my $g2p_panel (keys %$g2p_panels) {
  foreach my $organ_name ( @{ $g2p_panels->{$g2p_panel} } ) {
    my $organ = $organ_adaptor->fetch_by_name($organ_name);
    my $gfd_organs = $GFD_organ_adaptor->fetch_all_by_Organ($organ); 
    foreach my $gfd_organ (@$gfd_organs) {
      my $GFD_id = $gfd_organ->get_GenomicFeatureDisease->dbID;
      $panel_2_GFD->{$g2p_panel}->{$GFD_id} = 1; 
    }
  }
}

#foreach my $g2p_panel (keys %$panel_2_GFD) {
#  my $GFD_count = scalar keys %{$panel_2_GFD->{$g2p_panel}};
#  print "$g2p_panel $GFD_count\n";
#}

# fetch GFD by GFD id
# fetch GFD_actions, phenotypes, publications, Organ specificity

foreach my $g2p_panel (keys %$panel_2_GFD) {
  my $panel_attrib_id = $attrib_adaptor->attrib_id_for_value($g2p_panel);
  foreach my $GFD_id (keys %{$panel_2_GFD->{$g2p_panel}}) {
    my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id); 
    my $GFD_actions = $GFD_action_adaptor->fetch_all_by_GenomicFeatureDisease($GFD);
    my $GFD_phenotypes = $GFD_phenotype_adaptor->fetch_all_by_GenomicFeatureDisease($GFD);
    my $GFD_publications = $GFD_publication_adaptor->fetch_all_by_GenomicFeatureDisease($GFD); 
    my $GFD_organs = $GFD_organ_adaptor->fetch_all_by_GenomicFeatureDisease($GFD);
    
    # new GFD entry

    my $genomic_feature = $GFD->get_GenomicFeature;
    my $disease = $GFD->get_Disease;
    my $DDD_attrib = $GFD->DDD_category_attrib;


    my $new_GFD = $GFD_adaptor->fetch_by_GenomicFeature_Disease_panel_id($genomic_feature, $disease, $panel_attrib_id);    
    my $new_GFD_id;
    my $new_genomic_feature_disease;
    if ($new_GFD) {
      $new_GFD_id = $new_GFD->dbID;
      $new_genomic_feature_disease = $GFD_adaptor->fetch_by_dbID($new_GFD_id);
    } else {
      $new_genomic_feature_disease = G2P::GenomicFeatureDisease->new({
        genomic_feature_id => $genomic_feature->dbID,
        disease_id => $disease->dbID,
        panel_attrib => $panel_attrib_id,
        DDD_category_attrib => $DDD_attrib,
        registry => $registry,
      });     
      $new_genomic_feature_disease = $GFD_adaptor->store($new_genomic_feature_disease, $user);
      $new_GFD_id = $new_genomic_feature_disease->dbID;
    }

    my $new_GFD_actions = $GFD_action_adaptor->fetch_all_by_GenomicFeatureDisease($new_genomic_feature_disease);
    my $new_GFD_actions_lookup = {};

    foreach my $new_GFD_action (@$new_GFD_actions) {
      my $allelic_requirement_attrib = $new_GFD_action->allelic_requirement_attrib;
      my $mutation_consequence_attrib = $new_GFD_action->mutation_consequence_attrib;
      $new_GFD_actions_lookup->{"$new_GFD_id\t$allelic_requirement_attrib\t$mutation_consequence_attrib"} = 1;
    }

    foreach my $GFD_action (@$GFD_actions) {
      my $allelic_requirement_attrib = $GFD_action->allelic_requirement_attrib;
      my $mutation_consequence_attrib = $GFD_action->mutation_consequence_attrib;
      
      if (!$new_GFD_actions_lookup->{"$new_GFD_id\t$allelic_requirement_attrib\t$mutation_consequence_attrib"}) {     
 
        my $new_GFD_action = G2P::GenomicFeatureDiseaseAction->new({
          genomic_feature_disease_id => $new_GFD_id,
          allelic_requirement_attrib => $allelic_requirement_attrib,
          mutation_consequence_attrib => $mutation_consequence_attrib,  
          user_id => undef,
        });

        $new_GFD_action = $GFD_action_adaptor->store($new_GFD_action, $user);

      }
    }

    my $new_GFD_phenotypes = $GFD_phenotype_adaptor->fetch_all_by_GenomicFeatureDisease($new_genomic_feature_disease);
    my $new_GFD_phenotypes_lookup = {};
    foreach my $new_GFD_phenotype (@$new_GFD_phenotypes) {
      my $phenotype_id = $new_GFD_phenotype->get_Phenotype->dbID;
      $new_GFD_phenotypes_lookup->{"$new_GFD_id\t$phenotype_id"} = 1;
    }

    foreach my $GFD_phenotype (@$GFD_phenotypes) {
      my $phenotype_id = $GFD_phenotype->get_Phenotype->dbID;
      if (!$new_GFD_phenotypes_lookup->{"$new_GFD_id\t$phenotype_id"}) {
        my $new_GFDP = G2P::GenomicFeatureDiseasePhenotype->new({
          genomic_feature_disease_id => $new_GFD_id,
          phenotype_id => $phenotype_id,
          registry => $registry,
        });
        $GFD_phenotype_adaptor->store($new_GFDP);
      }
    } 

    my $new_GFD_publications = $GFD_publication_adaptor->fetch_all_by_GenomicFeatureDisease($new_genomic_feature_disease);
    my $new_GFD_publications_lookup = {};
    foreach my $new_GFD_publication (@$new_GFD_publications) {
      my $publication_id = $new_GFD_publication->get_Publication->dbID;
      $new_GFD_publications_lookup->{"$new_GFD_id\t$publication_id"} = 1;
    }

    foreach my $GFD_publication (@$GFD_publications) {
      my $publication_id = $GFD_publication->get_Publication->dbID;
      if (!$new_GFD_publications_lookup->{"$new_GFD_id\t$publication_id"}) {
        my $new_GFD_publication = G2P::GenomicFeatureDiseasePublication->new({
          genomic_feature_disease_id => $new_GFD_id,
          publication_id => $publication_id,
          registry => $registry,
        });
        $GFD_publication_adaptor->store($new_GFD_publication);
      }
    }

    my $new_GFD_organs = $GFD_organ_adaptor->fetch_all_by_GenomicFeatureDisease($new_genomic_feature_disease);
    my $new_GFD_organs_lookup = {};
    foreach my $new_GFD_organ (@$new_GFD_organs) {
      my $organ_id = $new_GFD_organ->get_Organ->dbID;
      $new_GFD_organs_lookup->{"$new_GFD_id\t$organ_id"} = 1;
    }
  
    foreach my $GFD_organ (@$GFD_organs) {
      my $organ_id = $GFD_organ->get_Organ->dbID;
      if (!$new_GFD_organs_lookup->{"$new_GFD_id\t$organ_id"}) {
        my $new_GFD_organ =  G2P::GenomicFeatureDiseaseOrgan->new({
          organ_id => $organ_id,
          genomic_feature_disease_id => $new_GFD_id,
          registry => $registry, 
        });
        $GFD_organ_adaptor->store($new_GFD_organ);
      }
    }
  }
}

