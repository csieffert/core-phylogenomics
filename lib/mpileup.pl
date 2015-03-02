#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;

my ($samtools,$bcftools,$reference,$bam,$bcf);
GetOptions('s|samtools-path=s' => \$samtools,
	   'b|bcftools-path=s' => \$bcftools,
	   'r|reference=s' => \$reference,
	   'bam=s' => \$bam,
	   'out-bcf=s' => \$bcf);

die "Error: no samtools path not defined" if (not defined $samtools);
die "Error: no bcftools path defined" if (not defined $bcftools);
die "Error: reference not defined" if (not defined $reference);
die "Error: no reference exists" if (not -e $reference);
die "Error: bam not defined" if (not defined $bam);
die "Error: bam does not exist" if (not -e $bam);
die "Error: no out-bcf defined" if (not defined $bcf);


#fix issue using sed  where mpileup will produce empty key/value pair in INFO column with two ';;' in a row. It will cause bcftools to segmentation fault.

my $command = "$samtools mpileup -BQ0 -d100000 -I -uf \"$reference\" \"$bam\" | $bcftools call -c | sed 's/;;/;/g' | $bcftools view -O b -o \"$bcf\"";
print "Running $command\n";
system($command) == 0 or die "Could not run $command";

die "Error: no output bcf file=$bcf produced" if (not -e $bcf);


#create index file
$command = "$bcftools index -f \"$bcf\"";
print "Running $command\n";
system($command) == 0 or die "Could not run $command";

die "Error: no output bcf file=$bcf produced" if (not -e "$bcf");
