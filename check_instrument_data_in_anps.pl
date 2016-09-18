#!/usr/bin/env genome-perl

use Genome;
use Set::Scalar;

# Takes two AnP ids and then reports any Illumina sequencing data unique to either one.
my ($anp1, $anp2) = @ARGV;
my $anp1_obj = Genome::Config::AnalysisProject->get($anp1);
my $anp2_obj = Genome::Config::AnalysisProject->get($anp2);

my @instrument_data1 = map { $_->id } Genome::InstrumentData::Solexa->get(analysis_projects => $anp1_obj);
print STDERR "Found ", scalar(@instrument_data1), " from $anp1\n";
my @instrument_data2 = map { $_->id } Genome::InstrumentData::Solexa->get(analysis_projects => $anp2_obj);
print STDERR "Found ", scalar(@instrument_data2), " from $anp2\n";

my $set1 = Set::Scalar->new(@instrument_data1);
my $set2 = Set::Scalar->new(@instrument_data2);

my $set1_unique = $set1 - $set2;
if ($set1_unique && !$set1_unique->is_empty) {
    print "Found instrument data in $anp1 not in $anp2:\n";
    print join("/", @$set1_unique),"\n";
}

my $set2_unique = $set2 - $set1;
if ($set2_unique && !$set2_unique->is_empty) {
    print "Found instrument data in $anp2 not in $anp1:\n";
    print join("/", @$set2_unique),"\n";
}

