#!/usr/bin/env perl

use strict;
use warnings;

use Genome;

my ($model_id, $flowcell_id) = @ARGV;

my $model = Genome::Model->get($model_id);
unless ($model) {
    die "Unable to retrieve model with id $model_id!\n";
}

my @instrument_data = grep { $_->subclass_name eq 'Genome::InstrumentData::Solexa' } $model->instrument_data;
unless (@instrument_data) {
    die "No Illumina instrument data for $model_id\n";
}

my @data_to_remove;
for my $inst_datum (@instrument_data) {
    unless ($inst_datum->flow_cell_id eq $flowcell_id) {
        push @data_to_remove, $inst_datum;
    }
}

if (@data_to_remove) {
    my $cmd = Genome::Model::Command::InstrumentData::Unassign->create( model => $model, instrument_data => \@data_to_remove);
    my $rv = $cmd->execute;
    unless ($rv) {
        die "Unable to remove instrument data!\n";
    }
    else {
        UR::Context->commit() or die "Unable to commit!\n";
    }
}
else {
    warn "No data to remove!\n";
}
