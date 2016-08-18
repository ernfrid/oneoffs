#!/usr/bin/env genome-perl

use strict;
use warnings;

# This is intended to take a mapping of sample name to file name.
# It checks both VCFs and BAM/SAM and should be able to handle both zipped and plain text forms
# Input is expected to be two columns on standard in
sub sample_from_bam_header {
    my @header_lines = @_;
    my @sample_lines = grep { /^\@RG/ } @header_lines;

    my %map;
    for my $line (@sample_lines) { 
        chomp $line;
        my @fields = split "\t", $line;
        for my $field (@fields) {
            next if $field =~ /^\@RG/;
            my ($tag, $value) = split ":", $field;
            $value =~ s/"//g;
            if(!exists($map{tag})) {
                $map{$tag} = $value;
            }
            else {
                if($map{tag} ne $value) { 
                    die "Multiple Sample names in BAM\n";
                }
            }
        }
    }
    return $map{'SM'};
}

sub sample_from_vcf_header {
    my @header_lines = @_;
    my @main_header = grep { /^#CHROM/ } @header_lines;
    if(@main_header != 1) {
        die "Invalid number of VCF header lines\n";
    }
    chomp $main_header[0];
    my @fields = split "\t", $main_header[0];
    my ($pre, $sample) = @fields[-2, -1];
    if ($pre ne 'FORMAT') {
        # line has more than one sample or no samples at all
        die "VCF has more than one SAMPLE field or no samples at all\n";
    }
    return $sample;
}

sub get_sample_from_file {
    my $file = shift;
    my $progstring = shift;
    my $func = shift;
    my @header_lines = `$progstring $file`;
    unless(@header_lines) {
        die "Unable to grab header for $file\n";
    }
    return &$func(@header_lines);
}

while(<>) {
    chomp;
    my ($claimed_sample, $file) = split "\t";
    my $file_sample;
    unless(-e $file) {
        warn "$file no longer exists. Drat!\n";
    }
    else {
        if ($file =~ /\.g*vcf\.\S{0,2}/) {
            $file_sample = get_sample_from_file($file, q{bcftools1.2 view -h}, \&sample_from_vcf_header);
        }
        elsif ($file =~ /\.[bs]am$/) {
            $file_sample = get_sample_from_file($file, q{samtools1.2 view -H}, \&sample_from_bam_header);
        }
        if ($file_sample ne $claimed_sample) {
            warn "Found $file_sample in $file, but expected $claimed_sample\n";
        }
    }
}

