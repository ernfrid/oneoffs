#!/usr/bin/env genome-perl

use strict;
use warnings;
use File::Basename;
use IO::File;
use Switch;

=cut
Conventions named as follows:
cd15f9cb49324c8b90766ee1415426e5.revert.bam.flagstat
cd15f9cb49324c8b90766ee1415426e5.revert.bam.flagstat_both_mapped_non_supp
cd15f9cb49324c8b90766ee1415426e5.revert.bam.flagstat_orphan_mapped_end_non_supp
cd15f9cb49324c8b90766ee1415426e5.revert.bam.flagstat_orphan_unmapped_end_non_supp
cd15f9cb49324c8b90766ee1415426e5.revert.bam.flagstat_supp
=cut

while(<>) {
    chomp;
    my @fields = split /\./;
    my $type = filename_to_type($fields[-1]);
    my ($sample, $pipeline) = filename_to_sample_pipeline($_);
    my $fh = IO::File->new($_) or die "Unable to read $_\n";
    my $dups;
    my $total;
    while (my $line = $fh->getline) {
        chomp $line;
        my @fields2 = split " ", $line;
        if ($fields2[3] eq 'in') {
            $total = $fields2[0] + $fields2[2];
            print join("\t", $sample, $pipeline, "${type}_reads", $fields2[0] + $fields2[2]), "\n";
        }
        elsif ($fields2[3] eq "duplicates") {
            $dups = $fields2[0] + $fields2[2];
            print join("\t", $sample, $pipeline, "${type}_duplicates", $fields2[0] + $fields2[2]), "\n";
        }
    }
    print join("\t", $sample, $pipeline, "${type}_rate", $dups/$total), "\n";
}

sub filename_to_type {
    my ($name) = @_;
    switch ($name) {
        case /flagstat$/ { return 'total'; }
        case /flagstat_both_mapped_non_supp/ { return 'primary_both_mapped'; }
        case /flagstat_orphan_mapped_end_non_supp/ { return 'primary_orphan_mapped_end'; }
        case /flagstat_orphan_unmapped_end_non_supp/ { return 'primary_orphan_unmapped_end'; }
        case /flagstat_supp_both_mapped/ { return 'supplementary_both_mapped'; }
        case /flagstat_supp/ { return 'supplementary'; }
    }
}

sub filename_to_sample_pipeline {
    my ($name) = @_;
    my $filename = fileparse($name, qw( .cram.flagstat .cram.flagstat_both_mapped_non_supp .cram.flagstat_orphan_mapped_end_non_supp .cram.flagstat_orphan_unmapped_end_non_supp .cram.flagstat_supp_both_mapped .cram.flagstat_supp ));
    my ($sample, $pipeline, $rep) = split '\.', $filename;
    if ($rep) {
        $pipeline .= $rep;
    }
    return ($sample, $pipeline);
}
