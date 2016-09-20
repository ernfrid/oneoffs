#!/usr/bin/env perl

use strict;
use warnings;

use Genome;
use Set::Scalar;
use Data::Dumper;

my @anp_ids = @ARGV;
my @anps = Genome::Config::AnalysisProject->get(id => \@anp_ids);

my @raw_breadth_values = qw( 5 10 15 20 25 30 40 50 60 70 80 90 100 );
my $coverage_breadth_header = join("\t", map { "Pct_${_}X" } @raw_breadth_values);

print join("\t", qw(Sample Analysis_Project Model Build Primary_flowcell Primary_date Primary_machine All_flowcells nLanes nFlowcells Freemix Median_Insert_Size MAD_Insert_Size Mean_Insert_Size SD_Insert_Size GC_Dropout AT_Dropout Flagstat_Duplication_Rate Mean_Coverage Haploid_Coverage New_Haploid_Coverage Illumina_Coverage Picard_Mismatch_Rate Picard_HQ_Error_Rate Picard_Indel_Rate Read1_Picard_Mismatch_Rate Read1_Picard_HQ_Error_Rate Read1_Picard_Indel_Rate Read2_Picard_Mismatch_Rate Read2_Picard_HQ_Error_Rate Read2_Picard_Indel_Rate Picard_Percent_Reads_Aligned Picard_Percent_Reads_Aligned_In_Pairs Picard_Percent_Adapter Picard_Percent_Chimeras Flagstat_Percentage_Proper_Pair Flagstat_Percentage_Interchromosomal_Pair), $coverage_breadth_header), "\n";

for my $anp (@anps) {
    #my @models = Genome::Model->get(analysis_project => $anp, 'config_profile_item.tag_names' => 'production qc') or die "Unable to get a models for ", $anp->name, "\n";
    my $iter = Genome::Model->create_iterator(analysis_project => $anp, subclass_name => 'Genome::Model::SingleSampleGenotype') or die "Unable to get a models for ", $anp->name, "\n";
    while (my $model = $iter->next) {
        unless($model->last_succeeded_build) {
            next;
        }
        my $flowcells = flow_cells($model);
        my $primary = primary_flowcell($flowcells);
        my $dates = run_dates($model);
        my $primary_date = key_for_flowcell($dates, $primary);
        my $machines = machines($model);
        my $primary_machine = key_for_flowcell($machines, $primary);
        my $fm = freemix($model);
        my @instrument_data = $model->instrument_data;
        print join("\t", $model->subject->name, $anp->name, $model->id, $model->last_succeeded_build->id, $primary, $primary_date, $primary_machine, join(",", keys %$flowcells), scalar(@instrument_data), scalar(keys %$flowcells), $fm, insert_size_metrics($model), gc_bias_metrics($model), flagstat_duplication_rate($model), coverage($model), haploid_coverage($model), new_haploid_coverage($model), illumina_coverage($model), mismatch_rate_metrics($model), alignment_metrics($model), flagstat_alignment_metrics($model), breadth_metrics($model)), "\n";
    }
}

sub qc_metrics_hash {
    my ($model) = @_;
    my $build = $model->last_succeeded_build;
    return undef unless $build;
    my $qc_results = Set::Scalar->new();
    $qc_results->insert(grep {$_->isa('Genome::Qc::Result')} $build->results);
    if ($qc_results->size == 1) {
        my ($result) = $qc_results->members;
        my %metrics = $result->get_unflattened_metrics;
        return \%metrics;
    }
    else {
        warn "More than one set of unique QC results, not sure yet what this means\n";
        print Dumper $qc_results;
        die;
    }
}

sub gc_bias_metrics {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return @{$metrics}{qw( GC_DROPOUT AT_DROPOUT )},
}

sub insert_size_metrics {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return @{$metrics->{'FR'}}{qw( MEDIAN_INSERT_SIZE MEDIAN_ABSOLUTE_DEVIATION MEAN_INSERT_SIZE STANDARD_DEVIATION ) };
}

sub coverage {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return $metrics->{'MEAN_COVERAGE'};
}

sub haploid_coverage {
    # This is a calculated metric located in genome qc build-metrics
    # This code was copied from there
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return ( $metrics->{PAIR}->{PF_ALIGNED_BASES} * ( 1 - _calculate_duplication_rate($model) )) / $metrics->{GENOME_TERRITORY};
}

sub illumina_coverage {
    # Calculate coverage as recommended by Illumina's whitepaper here: http://www.illumina.com/content/dam/illumina-marketing/documents/products/technotes/hiseq-x-30x-coverage-technical-note-770-2014-042.pdf
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return $metrics->{'MEAN_COVERAGE'} * ( ( 1 - $metrics->{'PCT_EXC_DUPE'} - $metrics->{'PCT_EXC_OVERLAP'} ) / ( 1 - $metrics->{'PCT_EXC_TOTAL'} ));
}

sub new_haploid_coverage {
    # Calculate coverage similar to Illumina's whitepaper here: http://www.illumina.com/content/dam/illumina-marketing/documents/products/technotes/hiseq-x-30x-coverage-technical-note-770-2014-042.pdf
    my ($model, $original_coverage) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    if (not defined $original_coverage) {
        $original_coverage = $metrics->{'MEAN_COVERAGE'};
    }
    return $original_coverage * ( ( 1 - $metrics->{'PCT_EXC_DUPE'} ) / ( 1 - $metrics->{'PCT_EXC_TOTAL'} ));
}

sub breadth_metrics {
    my ($model) = @_;
    my @breadth_values = map { "PCT_${_}X" } @raw_breadth_values;
    my $metrics = qc_metrics_hash($model) or return ((undef) x scalar(@raw_breadth_values));
    return @{$metrics}{@breadth_values};
}


sub mismatch_rate_metrics {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return (@{$metrics->{'PAIR'}}{ qw( PF_MISMATCH_RATE PF_HQ_ERROR_RATE PF_INDEL_RATE ) },
        @{$metrics->{'FIRST_OF_PAIR'}}{ qw( PF_MISMATCH_RATE PF_HQ_ERROR_RATE PF_INDEL_RATE ) },
        @{$metrics->{'SECOND_OF_PAIR'}}{ qw( PF_MISMATCH_RATE PF_HQ_ERROR_RATE PF_INDEL_RATE ) });
}

sub alignment_metrics {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return (@{$metrics->{'PAIR'}}{ qw( PCT_PF_READS_ALIGNED PCT_READS_ALIGNED_IN_PAIRS PCT_ADAPTER PCT_CHIMERAS ) })
}

sub flagstat_alignment_metrics {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return (@{$metrics}{ qw( reads_mapped_in_proper_pairs_percentage reads_mapped_in_interchromosomal_pairs_percentage ) })
}

sub _calculate_duplication_rate {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return $metrics->{'reads_marked_duplicates'} / $metrics->{PAIR}->{PF_READS_ALIGNED};
}

sub flagstat_duplication_rate {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return sprintf "%0.02f", _calculate_duplication_rate($model) * 100
}

sub freemix {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return $metrics->{'ALL'}{'FREEMIX'};
}

sub key_for_flowcell {
    my ($hash, $flowcell) = @_;
    for my $key (keys %$hash) {
        if (exists($hash->{$key}{$flowcell})) {
            return $key;
        }
    }
    return undef;
}

sub primary_flowcell {
    my ($hash) = @_;
    my ($primary) = sort { $hash->{$b} <=> $hash->{$a} } keys %$hash;
    return $primary;
}

sub flow_cells {
    my ($model) = @_;
    my %flowcells;
    for my $inst_data ($model->instrument_data) {
        $flowcells{$inst_data->flow_cell_id} += 1;
    }
    return \%flowcells;
}

sub run_dates {
    my ($model) = @_;
    #XXX these should be in chronological order
    my %dates;
    for my $inst_data ($model->instrument_data) {
        $dates{$inst_data->run_start_date_formatted}{$inst_data->flow_cell_id} += 1;
    }
    return \%dates;
}

sub machines {
    my ($model) = @_;
    my %machines;
    for my $inst_data ($model->instrument_data) {
        $machines{_illumina_machine_serial_number($inst_data->run_name)}{$inst_data->flow_cell_id} += 1;
    }
    return \%machines;
}


sub _illumina_machine_serial_number {
    my ($run_name) = @_;
    # XXX This could be a method on InstrumentData::Solexa if we want.
    my ($date, $machine, $run_id, $flow_cell) = split "_", $run_name;
    unless(defined $date
        && defined $machine
        && defined $run_id
        && defined $flow_cell) {
        warn "Unable to parse run_name properly from $run_name\n";
        $machine = ''
    }
    return $machine;
}
