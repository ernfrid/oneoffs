#!/usr/bin/env perl

use strict;
use warnings;

use Genome;

#assuming that we are reading in a list of sample names
my @samples = map { chomp; $_ } <>;

#only getting RefAlign here with our current default production strategy.
my @models = Genome::Model::ReferenceAlignment->get(subject_name => \@samples, processing_profile_id => 'df759124b70941a99288eedeccb0457f');
print join("\t", qw( model_id build_id library_name flowcells duplication_rate )), "\n";
for my $model (@models) { 
    my $build = $model->last_succeeded_build;
    my $metrics = $build->mark_duplicates_library_metrics_hash_ref;
    my $flowcells_for_library = flowcells_for_library($model);
    for my $lib (keys %$metrics) { 
        my $flowcells = join(",", sort keys %{$flowcells_for_library->{$lib}});
        print join("\t", $model->id, $build->id, $lib, $flowcells, $metrics->{$lib}{PERCENT_DUPLICATION}),"\n";
    }
}

sub flowcells_for_library {
    my ($model) = @_;
    my %flowcells;
    for my $instrument_data ($model->instrument_data) {
        next unless $instrument_data->isa('Genome::InstrumentData::Solexa');
        $flowcells{$instrument_data->library->name}{$instrument_data->flow_cell_id} = 1;
    }
    return \%flowcells;
}

