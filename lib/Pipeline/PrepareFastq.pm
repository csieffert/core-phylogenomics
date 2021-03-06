#!/usr/bin/env perl

package Pipeline::PrepareFastq;
use Pipeline;
@ISA = qw(Pipeline);

use strict;
use warnings;

use Logger;
use JobProperties;

use Stage;
use Stage::CopyInputFastq;
use Stage::CopyInputReference;
use Stage::FastQC;
use Stage::WriteProperties;
use Stage::TrimClean;
use Stage::DownSample;
use Stage::PrepareFastqFinal;

use File::Basename qw(basename dirname);
use File::Copy qw(copy move);
use File::Path qw(rmtree);
use Cwd qw(abs_path);

sub new
{
    my ($proto,$script_dir,$custom_config) = @_;

    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($script_dir,$custom_config);
    bless($self,$class);

    $self->_setup_stage_tables;

    $self->_check_stages;

    my $job_properties = $self->{'job_properties'};
    $job_properties->set_property('mode', 'prepare-fastq');

    $job_properties->set_dir('fastqc_dir', 'fastqc');
    $job_properties->set_dir('stage_dir', "stages");
    $job_properties->set_dir('fastq_dir', 'initial_fastq_dir');
    $job_properties->set_dir('downsampled_fastq_dir', 'downsampled_fastq');
    $job_properties->set_dir('cleaned_fastq', 'cleaned_fastq');
    $job_properties->set_dir('reference_dir', 'reference');

    return $self;
}

sub new_resubmit
{
    my ($proto,$script_dir, $job_properties) = @_;

    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new_resubmit($script_dir, $job_properties);
    bless($self,$class);

    $self->_setup_stage_tables;

    $self->_check_stages;

    $job_properties->set_dir('fastqc_dir', 'fastqc');
    $job_properties->set_dir('stage_dir', "stages");
    $job_properties->set_dir('fastq_dir', 'initial_fastq_dir');
    $job_properties->set_dir('downsampled_fastq_dir', 'downsampled_fastq');
    $job_properties->set_dir('cleaned_fastq', 'cleaned_fastq');
    $job_properties->set_dir('reference_dir', 'reference');

    return $self;
}

sub set_reference
{
	my ($self,$reference) = @_;

	die "Error: reference undefined" if (not defined $reference);
	die "Error: reference does not exist" if (not -e $reference);

	my $abs_reference_path = abs_path($reference);
	die "Error: abs path for reference not defined" if (not defined $abs_reference_path);
	$self->{'job_properties'}->set_abs_file('input_reference',$abs_reference_path);

	my $reference_name = basename($abs_reference_path);
	die "Undefined reference name" if (not defined $reference_name);
	$self->{'job_properties'}->set_file('reference',$reference_name);
}

sub set_input_fastq
{
	my ($self,$fastq_dir) = @_;

	die "Error: fastq_dir not defined" if (not defined $fastq_dir);
	die "Error: fastq_dir not a directory" if (not -d $fastq_dir);

	my $abs_fastq_path = abs_path($fastq_dir);
	die "Error: abs path for fastq_dir not defined" if (not defined $abs_fastq_path);
	$self->{'job_properties'}->set_abs_file('input_fastq_dir',$abs_fastq_path);
}

sub _setup_stage_tables
{
	my ($self) = @_;
	my $stage = {};

	$self->{'stage'} = $stage;
	$stage->{'all'} = [
	                  'write-properties',
			  'copy-input-reference',
			  'copy-input-fastq',
			  'trim-clean',
			  'downsample',
			  'fastqc',
			  'prepare-fastq-final'
	                 ];
	my %all_hash = map { $_ => 1} @{$stage->{'all'}};
	$stage->{'all_hash'} = \%all_hash;
	
	$stage->{'user'} = [
			    'trim-clean',
			    'downsample',
			    'fastqc',
			];
	
	$stage->{'valid_job_dirs'} = ['cleaned_fastq', 'fastqc_dir','downsampled_fastq_dir', 'reference_dir','log_dir','stage_dir', 'fastq_dir'];
	$stage->{'valid_other_files'} = [];

	my @valid_properties = join(@{$stage->{'valid_job_dirs'}},@{$stage->{'valid_other_files'}});
	$stage->{'valid_properties'} = \@valid_properties;
}

sub _initialize
{
    my ($self) = @_;

    my $job_properties = $self->{'job_properties'};
    $job_properties->build_job_dirs;

    my $log_dir = $job_properties->get_dir('log_dir');
    my $verbose = $self->{'verbose'};

    my $logger = new Logger($log_dir, $verbose);
    $self->{'logger'} = $logger;

    my $stage_table = {
                        'write-properties' => new Stage::WriteProperties($job_properties, $logger),
			'copy-input-reference' => new Stage::CopyInputReference($job_properties, $logger),
			'copy-input-fastq' => new Stage::CopyInputFastq($job_properties, $logger),
			'trim-clean' => new Stage::TrimClean($job_properties, $logger),
			'downsample' => new Stage::DownSample($job_properties, $logger),
			'fastqc' => new Stage::FastQC($job_properties, $logger),
			'prepare-fastq-final' => new Stage::PrepareFastqFinal($job_properties, $logger),
        };

    $self->{'stage_table'} = $stage_table;
}

1;
