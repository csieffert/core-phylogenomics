#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;
use FindBin;

my $script_dir = $FindBin::Bin;
my $filter_path = "$script_dir/filterVcf.pl";

die "Error: no $filter_path exists" if (not -e $filter_path);

my ($freebayes_params,$freebayes,$reference,$bam,$vcf,$bcftools,$bcf_split,$min_coverage);
my ($bcf_header);

GetOptions('f|freebayes-path=s' => \$freebayes,
	   'r|reference=s' => \$reference,
	   'bam=s' => \$bam,
	   'out-vcf=s' => \$vcf,
	   'out-bcf-split=s' => \$bcf_split,
           'bcf_header=s' => \$bcf_header,
	   'min-coverage=i' => \$min_coverage,
	   'freebayes-params=s' => \$freebayes_params,
	   'bcftools-path=s' => \$bcftools
       );

die "Error: no freebayes path defined" if (not defined $freebayes);
die "Error: no bcftools path defined" if (not defined $bcftools);
die "Error: reference not defined" if (not defined $reference);
die "Error: no reference exists" if (not -e $reference);
die "Error: bam not defined" if (not defined $bam);
die "Error: bam does not exist" if (not -e $bam);
die "Error: extract bcf header not defined" if (not defined $bcf_header);
die "Error: no out-vcf defined" if (not defined $vcf);
die "Error: no out-bcf-split defined" if (not defined $bcf_split);

if (defined $freebayes_params)
{
	if ($freebayes_params =~ /--min-coverage/ or $freebayes_params =~ /-!/)
	{
		die "do not set --min-coverage in freebayes-params it is set using the --min-coverage parameter";
	}
}
else
{
	die "Error: no freebayes-params set";
}
die "Error: min-coverage not defined" if (not defined $min_coverage);
die "Error: min-coverage=$min_coverage not valid" if ($min_coverage !~ /^\d+$/);

my $command =
"$freebayes ".
	    # input and output
            "--bam $bam ".
            "--vcf $vcf ".
            "--fasta-reference $reference ".
	    "--min-coverage $min_coverage ".$freebayes_params;

print "Running $command\n";
system($command) == 0 or die "Could not run $command";

die "Error: no output vcf file=$vcf produced" if (not -e $vcf);

#append the bcf contig header to the resuls from freebayes otherwise bcftools will fail since it NEEDS to have ##contig
$command = "sed -i \"s/##fileformat=VCFv4.1/##fileformat=VCFv4.1\\n$bcf_header/\" \"$vcf\"";
system($command) == 0 or die "Could not run $command";

$command = "$filter_path --noindels \"$vcf\" | $bcftools view -O b -o \"$bcf_split\"";
print "Running $command\n";
system($command) == 0 or die "Could not run $command";

die "Error: no split bcf file=$bcf_split produced" if (not -e $bcf_split);


#create index file
$command = "$bcftools index -f \"$bcf_split\"";
print "Running $command\n";
system($command) == 0 or die "Could not run $command";


die "Error: no output bcf file=$bcf_split produced" if (not -e "$bcf_split");
