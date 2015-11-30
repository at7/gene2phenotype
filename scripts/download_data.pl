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

#main();
main_sql();

sub main_sql {
  my $csv_file = $config->{csv_file};

  my $registry = G2P::Registry->new($config->{registry});
  
  my $dbh = $registry->{dbh};

  my $csv = Text::CSV->new ( { binary => 1, eol => "\r\n" } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
  open my $fh, ">:encoding(utf8)", "$csv_file" or die "$csv_file: $!";
  $csv->eol ("\r\n");  

  my $gfd_attribute_tables = {
    phenotype => {sql => 'SELECT gfdp.genomic_feature_disease_id, p.name FROM genomic_feature_disease_phenotype gfdp, phenotype p WHERE gfdp.phenotype_id = p.phenotype_id;'},
    organ => {sql => 'SELECT gfdo.genomic_feature_disease_id, o.name FROM genomic_feature_disease_organ gfdo, organ o WHERE gfdo.organ_id = o.organ_id'},
    publication => {sql => 'SELECT gfdp.genomic_feature_disease_id, p.pmid FROM genomic_feature_disease_publication gfdp, publication p WHERE gfdp.publication_id = p.publication_id;'},
  };

  my $gfd_attributes = {};
  foreach my $table (keys %$gfd_attribute_tables) {
    my $sql = $gfd_attribute_tables->{$table}->{sql};
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
    while (my $row = $sth->fetchrow_arrayref()) {
      my ($id, $value) = @$row;
      $gfd_attributes->{$id}->{$table}->{$value} = 1;
    }
  }

  my $attribs = {};
  my $sth = $dbh->prepare(q{SELECT attrib_id, value FROM attrib;});
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($id, $value) = @$row;
    $attribs->{$id} = $value;
  }

  $sth = $dbh->prepare(q{
    SELECT gfd.genomic_feature_disease_id, gf.gene_symbol, gf.mim, d.name, d.mim, gfd.DDD_category_attrib, gfda.allelic_requirement_attrib, gfda.mutation_consequence_attrib
    FROM genomic_feature_disease gfd
    LEFT JOIN genomic_feature_disease_action gfda ON gfd.genomic_feature_disease_id = gfda.genomic_feature_disease_id
    LEFT JOIN genomic_feature gf ON gfd.genomic_feature_id = gf.genomic_feature_id
    LEFT JOIN disease d ON gfd.disease_id = d.disease_id
  });
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my @row = $sth->fetchrow_array()) {
    my $gfd_id = shift @row;
    $row[0] ||= 'No gene symbol'; 
    $row[1] ||= 'No gene mim';
    $row[2] ||= 'No disease name';
    $row[3] ||= 'No disease mim';
    if ($row[4]) {
      $row[4] = $attribs->{$row[4]};
    } else {
      $row[4] = 'No DDD category';
    }
    if ($row[5]) {
      my @allelic_requirements = ();
      foreach my $id (split(',', $row[5])) {
        push @allelic_requirements, $attribs->{$id};
      }
      $row[5] = join(',', @allelic_requirements);
    } else {
      $row[5] = undef;
    }
    if ($row[6]) {
      my @mutation_consequences = ();
      foreach my $id (split(',', $row[6])) {
        push @mutation_consequences, $attribs->{$id};
      }
      $row[6] = join(',', @mutation_consequences);
    } else {
      $row[6] = undef;
    }

    if ($gfd_attributes->{$gfd_id}) {
      foreach my $table (qw/phenotype organ publication/) {
        if ($gfd_attributes->{$gfd_id}->{$table}) {
          push @row, join(';', keys %{$gfd_attributes->{$gfd_id}->{$table}});
        } else {
          push @row, undef;
        }
      }
    } else {
      push @row, (undef, undef, undef);
    }
    $csv->print ($fh, \@row);
  }

  close $fh or die "$csv: $!";
  system("gzip $csv_file");
}

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
