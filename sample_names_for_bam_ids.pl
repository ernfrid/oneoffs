#!/usr/bin/env perl

use strict;
use warnings;

use Genome;

while(<>) {
    my $file = $_;
    chomp $file;
    my ($id) = $file =~ /^(.+)\.bam$/;
    unless($id) {
        die "Unable to grab software id from bam name\n";
    }
    my $sr = Genome::SoftwareResult->get($id) or die "Unable to grab software results from $id\n";
    my @inst_data = $sr->instrument_data;
    unless(@inst_data) {
        die "Unable to grab instrument data for $file\n";
    }
    my %samples = map { $_->sample->name => 1 } @inst_data;
    for my $sample (keys %samples) {
        print "$file\t$sample\n";
    }
}

