#!/usr/bin/env perl

use strict;
use warnings;

use Genome;

my @anp_ids = @ARGV;
my @anps = Genome::Config::AnalysisProject->get(id => \@anp_ids);

print join("\t", qw(Sample Analysis_Project Model Build Primary_flowcell Primary_date Primary_machine All_flowcells nLanes nFlowcells Freemix Median_Insert_Size MAD_Insert_Size Mean_Insert_Size SD_Insert_Size GC_Dropout AT_Dropout Flagstat_Duplication_Rate)), "\n";

for my $anp (@anps) {
    my @models = Genome::Model->get(analysis_project => $anp, 'config_profile_item.tag_names' => 'production qc') or die "Unable to get a models for ", $anp->name, "\n";
    for my $model (@models) {
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
        print join("\t", $model->subject->name, $anp->name, $model->id, $model->last_succeeded_build->id, $primary, $primary_date, $primary_machine, join(",", keys %$flowcells), scalar(@instrument_data), scalar(keys %$flowcells), $fm, insert_size_metrics($model), gc_bias_metrics($model), flagstat_duplication_rate($model)), "\n";
    }
}

sub qc_metrics_hash {
    my ($model) = @_;
    my $build = $model->last_succeeded_build;
    return undef unless $build;
    my @qc_results = grep {$_->isa('Genome::Qc::Result')} $build->results;
    if (@qc_results == 1) {
        my %metrics = $qc_results[0]->get_unflattened_metrics;
        return \%metrics;
    }
    else {
        warn "More than one set of QC, not sure yet what this means\n";
        return undef;
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

sub flagstat_duplication_rate {
    my ($model) = @_;
    my $metrics = qc_metrics_hash($model) or return undef;
    return sprintf "%0.02f", $metrics->{'reads_marked_duplicates'} / $metrics->{'reads_mapped'} * 100;
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
        die "Unable to parse run_name properly from $run_name\n";
    }
    return $machine;
}