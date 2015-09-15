#!/usr/bin/env perl

use strict;
use warnings;

use Genome;
use Set::Scalar;
use Data::Dumper;

my @hcs3_3_39 = qw(
H7FKVCCXX
H7FKMCCXX
H7F3HCCXX
H77NGCCXX
H2TJGCCXX
H7F5WCCXX
H2TLMCCXX
H7FGLCCXX
H5N5HCCXX
H5MYVCCXX
H7F73CCXX
H7HJTCCXX
H7HKLCCXX
H7F7KCCXX
H7F5KCCXX
H7FGCCCXX
H7F57CCXX
H7GC3CCXX
);

my @hcs3_1_26 = qw(
H7FYVCCXX
H7FCYCCXX
H2TJ7CCXX
H7FYKCCXX
H7FLHCCXX
H7F7MCCXX
H7GFGCCXX
H7FJKCCXX
H7FKWCCXX
H7FJCCCXX
H7F5NCCXX
H7FJGCCXX
H7F3TCCXX
H7FK7CCXX
H5TM3CCXX
H7F5VCCXX
H7FJ7CCXX
H5N2FCCXX
H7HKJCCXX
H5TKCCCXX
H5NF7CCXX
);

# below are Jan 2015. Order is in rough order of preference
# Align only
# Align, no-sv
# Align with everything
my @pp_of_interest = qw(
df759124b70941a99288eedeccb0457f
911637d482a24f2e968853ba63bb6090
6283989b8e4d4b7f90b0af15b00eb472
);

# For each flow cell, grab all instrument data or samples, find all models that only have data from that sample
# Then look at sample duplication rate
# Since dup rate also depends on number of reads (a little), print out number of reads in BAM file. Then, at least, we may be able to regress out read number

for my $fc (@hcs3_1_26) {
    my $builds = builds_for_flowcell($fc, \@pp_of_interest);
    print_builds($fc, 'HCS3.1.26', $builds);
    #print "Found builds: ", join(",", @$builds), "\n";
}
for my $fc (@hcs3_3_39) {
    my $builds = builds_for_flowcell($fc, \@pp_of_interest);
    print_builds($fc, 'HCS3.3.39', $builds);
    #print "Found builds: ", join(",", @$builds), "\n";
}

sub print_builds {
    my ($fc, $hcs, $builds) = @_;
    for my $build (@$builds) {
        my $metrics = $build->mark_duplicates_library_metrics_hash_ref;
        if (scalar(keys %$metrics) != 1) {
            die "More than one library! OH NOES!\n";
        }
        my ($key) = keys %$metrics;
        my $dup_rate = $metrics->{$key}{'PERCENT_DUPLICATION'};
        my $reads = total_reads($build);
        print join("\t", $fc, $hcs, $build->subject_name, $build->id, $reads, $dup_rate), "\n";
    }
}

sub builds_for_flowcell {
    my ($flowcell, $processing_profiles) = @_;
    my @instrument_data = Genome::InstrumentData::Solexa->get(flow_cell_id => $flowcell);
    unless(@instrument_data) {
        die "Unable to find Illumina data from $flowcell\n";
    }

    my %instrument_data_by_sample;
    for my $instrument_data (@instrument_data) {
        push @{$instrument_data_by_sample{$instrument_data->sample->name}}, $instrument_data->id;
    }

    my @builds;
    for my $sample (keys %instrument_data_by_sample) {
        my @inputs = Genome::Model::Input->get(
            name => 'instrument_data',
            value_id => $instrument_data_by_sample{$sample}
        );
        my %models;
        for my $input (@inputs) {
            my $model = $input->model;
            next unless($model->class eq 'Genome::Model::ReferenceAlignment' && !$model->is_lane_qc);
            if(exists($models{$model->id})) {
                $models{$model->id}->insert($input->value_id);
            }
            else {
                $models{$model->id} = Set::Scalar->new($input->value_id);
            }
        }
        my %candidates;
        for my $model_id (keys %models) {
            my @model_builds = Genome::Model->get($model_id)->succeeded_builds;
            my $b;
            for my $build (@model_builds) {
                my $id_set = Set::Scalar->new($build->instrument_data_ids);
                if($id_set == $models{$model_id} && $id_set->size == 8) {
                    $b = $build;
                    last;
                }
            }
            unless($b) {
                next;
            }
            $candidates{$b->processing_profile_id} = $b;
        }

        my $candidate;
        for my $pp (@$processing_profiles) {
            if(exists($candidates{$pp})) {
                $candidate = $candidates{$pp};
                last;
            }
        }

        unless($candidate) {
            warn "Unable to find build for ", $sample, " with instrument data: ", join(",", @{$instrument_data_by_sample{$sample}}), ". Skipping.\n";
        }
        else {
            push @builds, $candidate;
        }
    }
    return \@builds;
}

sub total_reads {
    my ($build) = @_;
    my $total = 0;
    for my $id ($build->instrument_data) {
        $total += $id->read_count;
    }
    return $total;
}

