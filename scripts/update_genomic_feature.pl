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

main();

sub main {
  my $gene_names = {};
  my $fh = FileHandle->new($config->{gtf_file}, 'r');
  my $gene_id_2_gene_name = {}; 
  my $gene_name_2_gene_id = {};
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
    my $gene_name = $attribs{gene_name};
    $gene_name =~ s/"//g;
    my $gene_id = $attribs{gene_id}; 
    $gene_id =~ s/"//g;
    $gene_id_2_gene_name->{$gene_id} = $gene_name;
    $gene_name_2_gene_id->{$gene_name} = $gene_id;
  }
  $fh->close();

  if ($config->{test}) {
    die ('A working_dir must be defiened (--working_dir)') unless (defined($config->{working_dir}));
    my $working_dir = $config->{working_dir};
    my $fh_out = FileHandle->new("$working_dir/ensembl_genes.txt", 'w'); 
    foreach my $gene_id (keys %$gene_id_2_gene_name) {
      my $gene_name = $gene_id_2_gene_name->{$gene_id};
      print $fh_out "$gene_id\t$gene_name\n";
    }
    $fh_out->close();
  }

  my $gf_ids_in_GFDs = genomic_feature_ids_from_GFDs(); 

  my $genomic_features_from_db = load_genomic_feature_from_db();

  my $delete_gfs = {};

  my $gfa = $registry->get_adaptor('genomic_feature');
  my $gfda = $registry->get_adaptor('genomic_feature_disease');
  foreach my $gene_symbol (keys %$genomic_features_from_db) {
    if (!$gene_name_2_gene_id->{$gene_symbol}) {
      foreach my $gf_id (keys %{$genomic_features_from_db->{$gene_symbol}}) {
        if (!$gf_ids_in_GFDs->{$gf_id}) {
          $delete_gfs->{$gf_id} = 1;
        }
      }     
    }
  }  
  
  delete_from_genomic_feature($delete_gfs);

  $genomic_features_from_db = load_genomic_feature_from_db();
  my $insert_gfs = {};

  while (my ($gene_name, $gene_id) = each %$gene_name_2_gene_id) {
    if (!$genomic_features_from_db->{$gene_name}) {
      $insert_gfs->{$gene_name} = $gene_id;
    }
  }

  insert_into_genomic_feature($insert_gfs);

  $genomic_features_from_db = load_genomic_feature_from_db();

  my $old_gfs = {};
  
  foreach my $gene_symbol (keys %$genomic_features_from_db) {
    if (!$gene_name_2_gene_id->{$gene_symbol}) {
      foreach my $gf_id (keys %{$genomic_features_from_db->{$gene_symbol}}) {
        if ($gf_ids_in_GFDs->{$gf_id}) {
          $old_gfs->{$gene_symbol} = $gf_id;
        }
      }     
    }
  }  

  my $delete_old_GF_ids = {};
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
        $dbh->do(qq{UPDATE genomic_feature_disease SET genomic_feature_id=$genomic_feature_id WHERE genomic_feature_disease_id=$GFD_id;}) or die $dbh->errstr; 
      }
    } else {
      print STDERR "No genomic_feature for $new_gene_symbol\n";
    }
    # store synoyms
    foreach my $new_gene_symbol (@keys_core_gene_names) {
      $dbh->do(qq{INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$new_gene_symbol');}) or die $dbh->errstr; 
    } 
    $dbh->do(qq{INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$old_gene_symbol');}) or die $dbh->errstr; 
  }

  foreach my $old_GF_id (keys %$delete_old_GF_ids) {
    $dbh->do(qq{DELETE FROM genomic_feature where genomic_feature_id = $old_GF_id;}) or die $dbh->errstr; 
  }
}

sub delete_from_genomic_feature {
  my $delete_gfs = shift;
  foreach my $gf_id (keys %$delete_gfs) {
    $dbh->do(qq{DELETE FROM genomic_feature where genomic_feature_id = $gf_id;}) or die $dbh->errstr; 
  }  
}

sub insert_into_genomic_feature {
  my $insert_gfs = shift;
  while (my ($gene_symbol, $stable_id) = each %$insert_gfs) {
    $dbh->do(qq{INSERT INTO genomic_feature(gene_symbol, ensembl_stable_id) VALUES('$gene_symbol', '$stable_id');}) or die $dbh->errstr; 
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

