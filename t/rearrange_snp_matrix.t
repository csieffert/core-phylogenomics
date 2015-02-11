#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;
use lib $FindBin::Bin.'/../lib';
use Test::More;
use Test::Exception;
use Stage::CopyInputFastq;
use Stage::RearrangeSNPMatrix;
use JobProperties;
use Logger;
use File::Temp 'tempdir';
use Getopt::Long;

my $tmp_dir;
my $keep_tmp;
my $script_dir = $FindBin::Bin;
if (not GetOptions('t|tmp-dir=s' => \$tmp_dir,'k|keep-tmp' => \$keep_tmp))
{
        die "Error: No tmp-dir indicated.";
}

$keep_tmp = 0 if (not defined $keep_tmp);

my $job_out = tempdir('rearrange_snp_matrixXXXXXX', CLEANUP => (not $keep_tmp), DIR => $tmp_dir) or die "Could not create temp directory";
my $logger = Logger->new($job_out);
my $properties = JobProperties->new($tmp_dir);
#set specific properties that would normally be set on command line or previous stages of the pipeline:
$properties->set_property('input_taxa_dir', '/Warehouse/Users/csieffert/core-phylogenomics/t/data/tree/input');
$properties->set_property('input_matrix_dir', '/Warehouse/Users/csieffert/core-phylogenomics/t/data/tree/input');
$properties->set_property('root_strain', 'VC-18');
$properties->set_property('tree_order', 'increasing');
$properties->set_property('inputMatrix', '/Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv');

my $testObject = Stage::RearrangeSNPMatrix->new($properties, $logger);

$testObject->execute();

#a list of fake input fastq files that should throw an error with verify_unique_file_names
#my @fastqFail = ['home/this.fastq', 'home/that.fastq', 'home/other.fastq'];
#dies_ok{$testObject->verify_unique_file_names(@fastqFail, 'home/this.fasta')} 'Duplicate file names are recognized and an error is thrown.'."\n";

#test that should pass
#my @fastqPass = ['home/path/this.fastq', 'home/path/that.fastq', 'home/path/other.fastq'];
#ok($testObject->verify_unique_file_names(@fastqPass, '/home/path/reference.fasta'), "Valid input file names are allowed."."\n");

done_testing();