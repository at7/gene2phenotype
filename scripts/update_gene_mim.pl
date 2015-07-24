#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;

use G2P::Registry;

my $config = {};

GetOptions(
  $config,
  'mim2gene_file=s',
  'registry_file=s',
  'update',
  'test',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));
die ('A mim2gene_file must be defiened (--mim2gene_file)') unless (defined($config->{mim2gene_file}));

my $registry = G2P::Registry->new($config->{registry_file});
my $dbh = $registry->{dbh};

main();

sub main {
  my $gene2mim = {};
  my $fh = FileHandle->new($config->{mim2gene_file}, 'r');
  while (<$fh>) {
    chomp;
    next if (/^#/);
    my @values = split/\t/;
    my $mim = $values[0];
    my $type = $values[1]; 
    my $gene_symbol = $values[3]; 
    if ($type eq 'gene') {
      if ($gene_symbol ne '-') {
        $gene2mim->{$gene_symbol}->{$mim} = 1;
      }
    }
  }
  $fh->close();

  my $GFA = $registry->get_adaptor('genomic_feature');

  my $gfs = $GFA->fetch_all();
  foreach my $gf (@$gfs) {
    my $mim = $gf->mim;
    my $name = $gf->gene_symbol(); 
    if (!$mim) {
      my $mims = $gene2mim->{$name};
      if (scalar keys %$mims == 1) {
        $mim = (keys %$mims)[0];
        $gf->mim($mim);
        $GFA->update($gf);
      }
    }
  }
}
