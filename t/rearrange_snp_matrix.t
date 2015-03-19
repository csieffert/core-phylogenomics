#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use Test::Exception;
use File::Compare;

my $command;
#==============================================================================
#UNIT TESTS
#=======VALID INPUT FUNCTIONALITY TESTS=============
#1 => verify that the script saves output in the proper file locations
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/1 -k -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/1 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy");
ok(-e 'data/tree/output/1/', "Output tree file in correct location.");
ok(-e 'data/tree/output/1/revisedMatrix.csv', "Revised matrix file in correct location.");

#2 => verify that the script does not make any alterations to the tree or matrix when none of the optional are set
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/2 -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/2 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy");
ok((compare('data/tree/output/2/phylogeneticTree.txt', 'data/tree/expected/2/phylogeneticTree.txt')==0), "Verify that the phylogenetic tree has remained unchanged.");
ok(!(-e 'data/tree/output/2/revisedMatrix.csv'), "Verify that the revised matrix file was not generated.");

#3 => verify that the tree will convert branch lengths to total SNP estimate
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/3 -c -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/3 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy");
ok((compare('data/tree/output/3/phylogeneticTree.txt', 'data/tree/expected/3/phylogeneticTree.txt')==0), "Verify that the phylogenetic tree has its branch lengths converted to total SNP estimates.");

#4 => verify that the tree is properly sorted in ascending order
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/4 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/4 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy");
ok((compare('data/tree/output/4/phylogeneticTree.txt', 'data/tree/expected/4/phylogeneticTree.txt')==0), "Verify that the phylogenetic tree is properly sorted in increasing order.");

#5 => verify that the tree is properly sorted in descending order
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/5 -s decreasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/5 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy");
ok((compare('data/tree/output/5/phylogeneticTree.txt', 'data/tree/expected/5/phylogeneticTree.txt')==0), "Verify that the phylogenetic tree is properly sorted in descending order.");

#6 => verify that the tree is properly re-rooted
system("perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/6 -r VC-18 -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/6 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy");
ok((compare('data/tree/output/6/phylogeneticTree.txt', 'data/tree/expected/6/phylogeneticTree.txt')==0), "Verify that the phylogenetic tree has its branch lengths converted to total SNP estimates.");

#=========INVALID INPUT ERROR HANDLING TESTS=========
#7 => verify that the script dies properly when an invalid phylogenetic tree
$command = "perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/7 -r VC-18 -s increasing -i data/tree/input/INVALIDpseudoalign.phy_phyml_tree.txt -o data/tree/output/7 -m data/tree/input/matrix.csv -p data/tree/input/pseudoalign.phy";
ok(system(`$command`)!=0, "Invalid newick files are not accepted.");

#8 => verify that the script dies properly when an invalid matrix.csv file is input
$command = "perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/7 -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/7 -m data/tree/input/INVALIDmatrix.csv -p data/tree/input/pseudoalign.phy";
ok(system(`$command`)!=0, "Invalid newick files are not accepted.");

#9 => verify that the script dies properly when an invalid pseudoalign.phy file is input
$command = "perl ../scripts/rearrange_snp_matrix.pl -t data/tree/output/7 -r VC-18 -s increasing -i data/tree/input/pseudoalign.phy_phyml_tree.txt -o data/tree/output/7 -m data/tree/input/matrix.csv -p data/tree/input/INVALIDpseudoalign.phy";
ok(system(`$command`)!=0, "Invalid pseudoalign.phy files are not accepted.");
#=============================================================================
done_testing();