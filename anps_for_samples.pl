#!/usr/bin/env genome-perl

use strict;
use warnings;

use Genome;

my @samples = @ARGV;

my @instrument_data = Genome::InstrumentData->get(sample_name => \@samples);

for my $inst_data (@instrument_data) {
    my @anp_names = map { $_->name } $inst_data->analysis_projects;
    print join(" ", $inst_data->id, $inst_data->sample_name, @anp_names), "\n";
}

