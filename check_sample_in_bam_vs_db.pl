#!/usr/bin/env genome-perl

use strict;
use warnings;

use Genome;

# This takes a list of instrument data ids and then checks the BAM, sample and library names in the BAM vs the DB

my @ids = @ARGV;

my @inst_data = Genome::InstrumentData->get(\@ids) or die "Unable to get instrument_data\n";

for my $id (@inst_data) {
    my $bam_path = $id->bam_path;
    my $sample = $id->sample_name;
    my $lib = $id->library_name;
    my ($bam_id, $bam_sample, $bam_library) = get_sample_info_from_bam($bam_path);
    if ($bam_id != $id->id) {
        die "Ids not equal for ".$id->id." and $bam_path\n";
    }
    if($bam_sample ne $sample) {
        warn "Sample unequal for ".$id->id." and $bam_path. Found $bam_sample, but expected $sample\n";
    }
    if($bam_library ne $lib) {
        warn "Library unequal for ".$id->id." and $bam_path. Found $bam_library, but expected $lib\n";
    }
}

sub get_sample_info_from_bam {
    my $bam = shift;
    my @header_lines = `samtools view -H $bam`;
    unless(@header_lines) {
        die "Unable to grab header for $bam\n";
    }
    my @sample_lines = grep { /^\@RG/ } @header_lines;
    unless(@sample_lines == 1) {
        die "Invalid number of RG lines in $bam\n";
    }
    my @fields = split "\t", $sample_lines[0];
    my %map;
    for my $field (@fields) {
        next if $field =~ /^\@RG/;
        my ($tag, $value) = split ":", $field;
        $value =~ s/"//g;
        if(!exists($map{tag})) {
            $map{$tag} = $value;
        }
        else {
            die "$tag already exists\n";
        }
    }
    return @map{qw(ID SM LB)};
}
