#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;

# perl update_genomic_feature.pl -registry_file registry -gtf_file Homo_sapiens.GRCh38.79.gtf

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
  
  my $genomic_features_from_db = load_genomic_feature_from_db();
  foreach my $gene_symbol (keys %$genomic_features_from_db) {
    foreach my $genomic_feature_id (keys %{$genomic_features_from_db->{$gene_symbol}}) {
      my $ensembl_stable_id = $genomic_features_from_db->{$gene_symbol}->{$genomic_feature_id};
      if ($ensembl_stable_id eq '\N') {
        $ensembl_stable_id = $gene_name_2_gene_id->{$gene_symbol};
        if ($ensembl_stable_id) {
          $dbh->do(qq{UPDATE genomic_feature SET ensembl_stable_id='$ensembl_stable_id' WHERE genomic_feature_id=$genomic_feature_id;}) or die $dbh->errstr; 
        }
      }
    }
  }

  foreach my $gene_symbol (keys %$gene_name_2_gene_id) {
    if (!$genomic_features_from_db->{$gene_symbol}) {
      my $ensembl_stable_id = $gene_name_2_gene_id->{$gene_symbol}; 
      $dbh->do(qq{INSERT INTO genomic_feature(gene_symbol, ensembl_stable_id) VALUES('$gene_symbol', '$ensembl_stable_id');}) or die $dbh->errstr; 
    }
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

