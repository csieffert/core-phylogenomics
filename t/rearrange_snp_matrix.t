#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use Test::Exception;
use File::Compare;


#==============================================================================
#UNIT TESTS
#=======VALID INPUT FUNCTIONALITY TESTS=============
#1 => verify that the script saves output in the proper file locations
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/1 -k -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/1 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");
ok(-e 'data/tree/output/1/', "Output tree file in correct location.\n");
ok(-e 'data/tree/output/1/revisedMatrix.csv', "Revised matrix file in correct location.\n");

#2 => verify that the script does not make any alterations to the tree or matrix when none of the optional are set
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/2 -k -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/2 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");
ok((compare('data/tree/output/2/phylogeneticTree.txt', 'data/tree/expected/2/phylogeneticTree.txt')==0), "Verify that the phylogenetic tree has remained unchanged.\n");
ok(!(-e 'data/tree/output/2/revisedMatrix.csv'), "Verify that the revised matrix file was not generated.\n");

#3 => verify that the tree will convert branch lengths to total SNP estimate
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/3 -k -c -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/3 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");

#4 => verify that the tree is properly sorted in ascending order
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/4 -k -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/4 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");

#5 => verify that the tree is properly sorted in descending order
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/5 -k -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/5 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");

#6 => verify that the tree is properly re-rooted
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/6 -k -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/6 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy");

#=========INVALID INPUT ERROR HANDLING TESTS=========
#7 => verify that the script dies properly when an invalid phylogenetic tree s provided
dies_ok(system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/7 -k -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/7 -m /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/matrix.csv -p /Course/MI_workshop_2014/day7/output-10-subsample-example/pseudoalign/pseudoalign.phy"));

#test that should pass
#my @fastqPass = ['home/path/this.fastq', 'home/path/that.fastq', 'home/path/other.fastq'];
#ok($testObject->verify_unique_file_names(@fastqPass, '/home/path/reference.fasta'), "Valid input file names are allowed."."\n");
#=============================================================================
done_testing();