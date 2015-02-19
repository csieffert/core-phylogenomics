#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use Test::Exception;

system("perl ../scripts/rearrange_snp_matrix.pl -t . -k 1 -r VC-18 -s increasing -i data/tree/input -o data/tree -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");

#==============================================================================
#ADDING UNIT TESTS HERE IN THE NEAR FUTURE

#a list of fake input fastq files that should throw an error with verify_unique_file_names
#my @fastqFail = ['home/this.fastq', 'home/that.fastq', 'home/other.fastq'];
#dies_ok{$testObject->verify_unique_file_names(@fastqFail, 'home/this.fasta')} 'Duplicate file names are recognized and an error is thrown.'."\n";

#test that should pass
#my @fastqPass = ['home/path/this.fastq', 'home/path/that.fastq', 'home/path/other.fastq'];
#ok($testObject->verify_unique_file_names(@fastqPass, '/home/path/reference.fasta'), "Valid input file names are allowed."."\n");

done_testing();