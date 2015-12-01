#!/software/bin/perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;

# perl update_genomic_feature.pl -registry_file registry -gtf_file Homo_sapiens.GRCh38.79.gtf

=begin
  - store all new gene_symbol, stable_id pairs from the gtf file
  - fetch all genomic_features from gene2phenotype database
  - fetch all genomic_feature_ids that are part of a genomic_feature_disease (GFD)
  - delete all entries from genomic_feature that are not present in the most recent gtf file and are not part of a GFD 
  - sort out entries that are not in the gtf file but are part of a GFD
=end
=cut

my $config = {};

GetOptions(
  $config,
  'gtf_file=s',
  'registry_file=s',
  'working_dir=s',
  'update',
  'test',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));
die ('A gtf_file must be defiened (--gtf_file)') unless (defined($config->{gtf_file}));

my $registry = G2P::Registry->new($config->{registry_file});
my $dbh = $registry->{dbh};

my $ensembl_registry = 'Bio::EnsEMBL::Registry';

$ensembl_registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous'
);

my $gene_adaptor = $ensembl_registry->get_adaptor('human', 'core', 'gene');
my $gfa = $registry->get_adaptor('genomic_feature');
my $gfda = $registry->get_adaptor('genomic_feature_disease');

my $GTF_stable_id_2_gene_symbol = {};
my $GTF_gene_symbol_2_stable_id = {};
my $gf_ids_in_GFDs = genomic_feature_ids_from_GFDs(); 
my $gf_ids_in_synonyms = genomic_feature_ids_from_synonyms();

main();

sub main {
  backup();
  read_from_gtf();
  delete_old_features();
  insert_new_features();
  store_synonyms();
  update_search();
#  foreign_key_checks();
}

sub backup {
  foreach my $table (qw/genomic_feature genomic_feature_disease genomic_feature_synonym/) {
    my $sth = $dbh->prepare(qq{
      SHOW TABLES LIKE 'BU_$table';
    });
    $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
    my @row = $sth->fetchrow_array;
    if (@row) {
      warn "Table BU_$table already exists\n";
      $dbh->do(qq{DROP TABLE BU_$table;}) or die $dbh->errstr; 
    }
    $sth->finish();
  }
  foreach my $table (qw/genomic_feature genomic_feature_disease genomic_feature_synonym/) {
    $dbh->do(qq{CREATE TABLE BU_$table LIKE $table;}) or die $dbh->errstr; 
    $dbh->do(qq{INSERT INTO BU_$table SELECT * FROM $table;}) or die $dbh->errstr; 
  }
}

sub read_from_gtf {
  my $fh = FileHandle->new($config->{gtf_file}, 'r');
  while (<$fh>) {
    next if(/^#/); #ignore header
    chomp;
    my @values = split/\t/;
    my $attributes = $values[8];
    my @add_attributes = split(";", $attributes);
    # store ids and additional information in second hash
    my %attribs = ();
    foreach my $attr ( @add_attributes ) {
      if ($attr =~ /gene_id/ || $attr =~ /gene_name/) {
        next unless $attr =~ /^\s*(.+)\s(.+)$/;
        my $type  = $1;
        my $value = $2;
        if ($type  && $value){
          $attribs{$type} = $value;
        }
      }
    }
    my $gene_symbol = $attribs{gene_name};
    $gene_symbol =~ s/"//g;
    my $stable_id = $attribs{gene_id}; 
    $stable_id =~ s/"//g;
    $GTF_stable_id_2_gene_symbol->{$stable_id} = $gene_symbol;
    $GTF_gene_symbol_2_stable_id->{$gene_symbol} = $stable_id;
  }
  $fh->close();
  if ($config->{test}) {
    die ('A working_dir must be defiened (--working_dir)') unless (defined($config->{working_dir}));
    my $working_dir = $config->{working_dir};
    my $fh_out = FileHandle->new("$working_dir/ensembl_genes.txt", 'w'); 
    while (my ($stable_id, $gene_symbol) = each %$GTF_stable_id_2_gene_symbol) {
      print $fh_out "$stable_id\t$gene_symbol\n";
    }
    $fh_out->close();
  }
}

sub delete_old_features {

=begin
  - delete old genomic_features that are not listed in the most recent GTF file
  - check that the old entry is not used in a genomic_feature_disease or synonym 
 
  - gene has synonym 
=end
=cut

  my $genomic_features_from_db = load_genomic_feature_from_db();

  my $delete_gfs = {};

  foreach my $gene_symbol (keys %$genomic_features_from_db) {
    if (!$GTF_gene_symbol_2_stable_id->{$gene_symbol}) { # not in the most recent GTF file
      foreach my $gf_id (keys %{$genomic_features_from_db->{$gene_symbol}}) {
        if (!$gf_ids_in_GFDs->{$gf_id} && !$gf_ids_in_synonyms->{$gf_id}) {
          $delete_gfs->{$gf_id} = 1;
        }
      }     
    }
  }  
  delete_from_genomic_feature($delete_gfs);
}

sub delete_from_genomic_feature {
  my $delete_gfs = shift;
  foreach my $gf_id (keys %$delete_gfs) {
    print STDERR "DELETE FROM genomic_feature where genomic_feature_id=$gf_id;\n";
    $dbh->do(qq{DELETE FROM genomic_feature where genomic_feature_id = $gf_id;}) or die $dbh->errstr; 
  }  
}

sub insert_new_features {
  my $genomic_features_from_db = load_genomic_feature_from_db();

  my $insert_gfs = {};

  while (my ($gene_symbol, $stable_id) = each %$GTF_gene_symbol_2_stable_id) {
    if (!$genomic_features_from_db->{$gene_symbol}) {
      $insert_gfs->{$gene_symbol} = $stable_id;
    }
  }
  insert_into_genomic_feature($insert_gfs);
}

sub insert_into_genomic_feature {
  my $insert_gfs = shift;
  while (my ($gene_symbol, $stable_id) = each %$insert_gfs) {
    print STDERR "INSERT INTO genomic_feature(gene_symbol, ensembl_stable_id) VALUES('$gene_symbol', '$stable_id');\n";
    $dbh->do(qq{INSERT INTO genomic_feature(gene_symbol, ensembl_stable_id) VALUES('$gene_symbol', '$stable_id');}) or die $dbh->errstr; 
  }
}

sub store_synonyms {
  my $genomic_features_from_db = load_genomic_feature_from_db();

  my $old_gfs = {};
  my $old_synonyms = {}; 
  foreach my $gene_symbol (keys %$genomic_features_from_db) {

    if (!$GTF_gene_symbol_2_stable_id->{$gene_symbol}) { # gene_symbol is not part of new GTF file

      foreach my $gf_id (keys %{$genomic_features_from_db->{$gene_symbol}}) { # check if genomic_feature is used in GFD
        # gene is used in a GFD but it is not an offical symbol in the GTF file, create a synonym entry 
        if ($gf_ids_in_GFDs->{$gf_id}) {
          $old_gfs->{$gene_symbol} = $gf_id;
        }
        # gene is used as a synonym
        if ($gf_ids_in_synonyms->{$gf_id}) {
          $old_synonyms->{$gf_ids_in_synonyms->{$gf_id}} = $gf_id;                            
        }
      }     
    }
  }  

  my $delete_old_GF_ids = {};

  # Sort out genomic_features that are part of a GFD but not part of the most recent GTF file. Try and find synonyms:
  foreach my $old_gene_symbol (keys %$old_gfs) {
    my $core_gene_names = {};
    my $old_genomic_feature = $gfa->fetch_by_gene_symbol($old_gene_symbol);
    my $old_genomic_feature_id = $old_genomic_feature->dbID();
    $delete_old_GF_ids->{$old_genomic_feature_id} = 1;
    my $genes = $gene_adaptor->fetch_all_by_external_name($old_gene_symbol);
    foreach my $gene (@$genes) {
      my $external_name = $gene->external_name;
      my $stable_id = $gene->stable_id;
      next if ($stable_id =~ /^LRG/);
      $core_gene_names->{$external_name} = 1;
    }

    my @keys_core_gene_names = keys %$core_gene_names; 
    my $new_gene_symbol = shift @keys_core_gene_names;
    my $genomic_feature = $gfa->fetch_by_gene_symbol($new_gene_symbol);
    my $genomic_feature_id;
    if ($genomic_feature) { 
      $genomic_feature_id = $genomic_feature->dbID;   
      my $GFDs = $gfda->fetch_all_by_GenomicFeature($old_genomic_feature); 
      foreach my $GFD (@$GFDs) {
        my $GFD_id = $GFD->dbID();
        # update all GFD with new genomic_feature_id !!!
        print STDERR "UPDATE genomic_feature_disease SET genomic_feature_id=$genomic_feature_id WHERE genomic_feature_disease_id=$GFD_id;\n";
        $dbh->do(qq{UPDATE genomic_feature_disease SET genomic_feature_id=$genomic_feature_id WHERE genomic_feature_disease_id=$GFD_id;}) or die $dbh->errstr; 
      }
    } else {
      print STDERR "No genomic_feature for $new_gene_symbol\n";
    }
    # store synoyms
    foreach my $new_gene_symbol (@keys_core_gene_names) {
      print STDERR "INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$new_gene_symbol');\n";
      $dbh->do(qq{INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$new_gene_symbol');}) or die $dbh->errstr; 
    } 
    print STDERR "INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$new_gene_symbol');\n";
    $dbh->do(qq{INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$old_gene_symbol');}) or die $dbh->errstr; 
  }

  foreach my $old_GF_id (keys %$delete_old_GF_ids) {
    $dbh->do(qq{DELETE FROM genomic_feature where genomic_feature_id = $old_GF_id;}) or die $dbh->errstr; 
  }

  # Delete old synonyms:
  while ( my($old_synonym, $genomic_feature_id) = each %$old_synonyms) {
    $dbh->do(qq{DELETE FROM genomic_feature_synonym WHERE genomic_feature_id=$genomic_feature_id AND genomic_feature_synonym='$old_synonym';}) or die $dbh->errstr; 
  }

}

sub load_genomic_feature_from_db {
  my $genomic_features = {}; 
  my $sth = $dbh->prepare(q{
    SELECT genomic_feature_id, gene_symbol, ensembl_stable_id FROM genomic_feature
  }); 
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($gf_id, $gene_symbol, $ensembl_stable_id);
  $sth->bind_columns(\($gf_id, $gene_symbol, $ensembl_stable_id));
  while (my $row = $sth->fetchrow_arrayref()) {
    $ensembl_stable_id ||= '\N';
    $genomic_features->{$gene_symbol}->{$gf_id} = $ensembl_stable_id;        
  } 
  $sth->finish();
  
  # quick QC
  foreach my $gene_symbol (keys %$genomic_features) {
    if (scalar keys %{$genomic_features->{$gene_symbol}} > 1) {
      print $gene_symbol, "\n";
    }
  } 
  return $genomic_features;
}

sub genomic_feature_ids_from_GFDs {
  my $genomic_features = {};
  my $sth = $dbh->prepare(q{
    SELECT distinct genomic_feature_id FROM genomic_feature_disease;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($gfd_id);
  $sth->bind_columns(\$gfd_id);
  while ($sth->fetch) {
    $genomic_features->{$gfd_id} = 1;
  }
  $sth->finish();
  return $genomic_features;
}

sub genomic_feature_ids_from_synonyms {
  my $genomic_features = {};
  my $sth = $dbh->prepare(q{
    SELECT genomic_feature_id, name FROM genomic_feature_synonym;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($gfd_id, $gene_symbol);
  $sth->bind_columns(\($gfd_id, $gene_symbol));
  while ($sth->fetch) {
    $genomic_features->{$gfd_id} = $gene_symbol;
  }
  $sth->finish();
  return $genomic_features;
}

sub update_search {
  # update search:
  $dbh->do(qq{TRUNCATE search;}) or die $dbh->errstr;
  $dbh->do(qq{INSERT IGNORE INTO search SELECT gene_symbol from genomic_feature;}) or die $dbh->errstr; 
  $dbh->do(qq{INSERT IGNORE INTO search SELECT name from disease;}) or die $dbh->errstr; 
  $dbh->do(qq{INSERT IGNORE INTO search SELECT name from genomic_feature_synonym;}) or die $dbh->errstr; 
}

sub foreign_key_checks {

}


