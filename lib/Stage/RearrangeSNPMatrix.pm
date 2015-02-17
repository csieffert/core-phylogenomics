#!/usr/bin/env perl

package Stage::RearrangeSNPMatrix;

use Stage;
use Bio::TreeIO;
use Text::CSV;
@ISA = qw(Stage);

use strict;
use warnings;

sub new
{
	my ($proto, $job_properties, $logger) = @_;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new($job_properties, $logger);
	bless($self,$class);

	$self->{'_stage_name'} = 'rearrange-snp-matrix';

	return $self; 
}

#Submodule to re-root the phylogenetic tree with the indicated strain.
#Input: 
#	$input_taxa_tree -> Bio::Phylo::Forest::Tree phylogenetic tree to re-root
#   $newRootStrain -> String name of the strain to root with
sub reRootTree
{
	my ($self, $input_taxa_tree, $newRootStrain) = @_;
	my $logger = $self->{'_logger'};
	my $newRoot = "'".$newRootStrain."'";
	foreach my $node ($input_taxa_tree->get_nodes()){ 
       if($node->id eq $newRoot)
       {
       	  $input_taxa_tree->reroot_at_midpoint($node, 'ROOT NODE');
		  $logger->log("The phylogenetic tree has been successfully re-rooted on strain: ".$node->id()."\n", 0);
		  return;	
       }
    }   
    $logger->log("The requested strain".$newRoot."could not be found in the phylogenetic tree.\n", 0);
}

#Submodule to rearrange the entries in matrix.csv to match the new phylogenetic ordering
#Input: 
#	$input_taxa_tree -> Bio::Phylo::Forest::Tree phylogenetic tree to re-root
#output: New matrix.csv file that matches the ordering of the re-rooted phylo tree
sub updateMatrixCsv
{
	my ($self, $input_taxa_tree) = @_;
	
	#open a new file handle to print the output to
	open(my $revisedMatrixCsv, '>revisedMatrix.csv') or die "Could not open the output file: $!";
	
	#open file handle for input matrix.csv file
	my $inputMatrixFile = $self->{'_job_properties'}->get_property('inputMatrix');
	open(my $data, '<', $inputMatrixFile) or die "Could not open '$inputMatrixFile' $!\n";
	
	my $csv = Text::CSV->new({ sep_char => '\t' });
	#hash the two-dimensional matrix as 'keyColumn:keyRow' : 'value' pairs to facilitate rearrangement 
	my %matrixHash = ();
	my @strainColumn=[];
	#parse the input matrix and retain the first row for strain names in @strainNames
	while (my $input = <$data>) {
		my @line = split(/\t/, $input);
		#add all of the strain names for each row
		if($line[0] eq 'strain'){
			@strainColumn = split(/ /, "@line");
		}
		else{
			my $strainRow = $line[0];
			my $index = 0;
			#hash the values in the matrix as 'keyColumn:keyRow' : 'value'
			foreach(@line){
				$matrixHash{"'".$strainColumn[$index]."'".':'."'".$strainRow."'"} = $_; 
				$index++; 
			}	
		}
	}
			
	#using reference tree, print a re-ordered matrix.csv file to the indicated file handle
	print $revisedMatrixCsv "strain\t";
	foreach($input_taxa_tree->get_nodes){
		if($_->is_Leaf()){
			print $revisedMatrixCsv $_->id."\t";
		}
	}
	print $revisedMatrixCsv "\n";
	foreach( $input_taxa_tree->get_nodes) {
		if($_->is_Leaf()){
    		my $rowNode = $_->id;
    		print $revisedMatrixCsv $_->id."\t";
    		foreach( $input_taxa_tree->get_nodes) {
    			if($_->is_Leaf()){
    				my $hashQuery = $rowNode.':'.$_->id;
    				my $hashResult = $matrixHash{$hashQuery};
    				print $revisedMatrixCsv $hashResult."\t";
    			}
    		}
    		print $revisedMatrixCsv "\n";	      
		}
    }
	close($revisedMatrixCsv);
	close($data); 
}

#Converts the branch lengths to an estimate of the total number of SNP differences and renames the nodes to match the format: '[STRAIN][[BRANCH_LENGTH], [SNP_ESTIMATE]]' 
#Input:
#	$input_taxa_tree -> Bio::Phylo::Forest::Tree phylogenetic tree to re-root
sub branchLengthToSNP
{
	my ($self, $input_taxa_tree) = @_;
	
	my $logger = $self->{'_logger'};
	my $inputPhyFile = $self->{'_job_properties'}->get_property('inputPhy');
	
	#parse the total SNP's in the tree from the input .phy file:
	open(my $inputPhy, "<", $inputPhyFile);
	my $input = <$inputPhy>;
	my @line = split(/\s/, $input);	
	
	my $treeTotalSNP = $line[2];
	my $internalNumber = 1;
	foreach my $node ( $input_taxa_tree->get_nodes ){
		  my $nodeBranchLength = $node->branch_length();
		  $nodeBranchLength = 0 if !defined $nodeBranchLength;
		  my $lengthToSNP = $nodeBranchLength*$treeTotalSNP;
		  my $nodeName = $node->id();
		  
          $node->id("'Internal".$internalNumber."[".(sprintf "%1.4f", $nodeBranchLength).",".(sprintf "%2.2f", $lengthToSNP)."]'") if !$node->is_Leaf;
          $node->id($nodeName."'[".(sprintf "%1.4f", $nodeBranchLength).",".(sprintf "%2.2f", $lengthToSNP)."]'") if $node->is_Leaf;
          print $node->id() if $node->is_Leaf;
          $internalNumber++ if !$node->is_Leaf;
    }
    $logger->log("Internal node branches have been re-labelled to show total estimated SNP differences.\n", 0);
    close($inputPhy);
}

#Exponentially scales branch lengths on the input tree to allow the user to make the final output more easily human readable.
#input:
#	$input_taxa_tree -> Bio::Phylo::Forest::Tree phylogenetic tree to re-root
#   $exponent -> the exponent to factor all branch lengths by
sub resizeTree
{
	my ($self, $input_taxa_tree, $exponent) = @_;
	
	my $logger = $self->{'_logger'};
	$input_taxa_tree->exponentiate($exponent);
	$logger->log("Branch lengths have been resized with an exponential factor of: ".$exponent."\n", 0);
}

sub execute
{	
	my ($self) = @_;
	my $logger = $self->{'_logger'};
	my $stage = $self->get_stage_name;
	my $taxa={};
	
	my $job_properties = $self->{'_job_properties'};
	my $taxa_file = $job_properties->get_property('input_taxa_dir');
	$taxa_file .= '/pseudoalign.phy_phyml_tree.txt';
	bless($taxa, "Bio::Phylo::Forest::Tree");
		
	#parse the newick format phylogeny generated by phyml into a Bio::Phylo::Forest::Tree object
	my $taxaIO = Bio::TreeIO->new(
		'-format'   => 'newick',
		'-order_by' => 'height',
    	'-file'   => $taxa_file
 	);
 	
 	$taxa = $taxaIO->next_tree;
 	
 	#reroot the tree if requested by user:
 	$self->reRootTree($taxa, $job_properties->get_property('root_strain')) if defined $job_properties->get_property('root_strain');
 	
 	#determine whether the tree should be re-sorted in decreasing or increasing order
 	if($job_properties->get_property('tree_order') eq "decreasing"){
 		$taxa->get_root_node->each_Descendent("revalpha");
 	}
 	elsif($job_properties->get_property('tree_order') eq "increasing"){
 		
 	}
 	#create a matrix.csv file to reflect the changes made to the phylogenetic tree
 	$self->updateMatrixCsv($taxa);
 	
 	$self->branchLengthToSNP($taxa);
 	
 	#print the new phylogenetic tree to the output file.
 	open(my $taxaout, '>phylogeneticTree.txt') or die "Could not open output file: $!";
 	             
 	print $taxaout $taxa->as_text('newick'); 
 	 	
 	close($taxaout);
}


