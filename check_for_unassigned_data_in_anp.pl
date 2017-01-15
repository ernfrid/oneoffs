#!/usr/bin/env genome-perl

use strict;
use warnings;

use Genome;
use Set::Scalar;

# Take an anp id on the command line 
my ($anp) = @ARGV;
my $anp_obj = Genome::Config::AnalysisProject->get($anp);
print STDERR "Found ", $anp_obj->name, " for $anp\n";

my @instrument_data = map { $_->id } Genome::InstrumentData::Solexa->get(analysis_projects => $anp_obj) or die "Unable to get instrument data for $anp\n";
print STDERR "Found ", scalar(@instrument_data), " from $anp\n";

my $anp_set = Set::Scalar->new(@instrument_data);

my $iter = Genome::Model->create_iterator(analysis_project => $anp_obj, subclass_name => 'Genome::Model::SingleSampleGenotype') or die "Unable to get models for ", $anp, "\n";

my @assigned_instrument_data;
while (my $model = $iter->next) {
    my $build = $model->last_succeeded_build;
    unless($build) {
        warn "No succeeded build found for ", $model->id, "\n";
        next;
    }
    my @assigned_ids = $build->instrument_data_ids;
    push @assigned_instrument_data, @assigned_ids;

}
my $used_set = Set::Scalar->new(@assigned_instrument_data);

my $unassigned_solexa = $anp_set - $used_set;

if ($unassigned_solexa && !$unassigned_solexa->is_empty) {
    print "Found unassigned Illumina data in $anp:\n";
    print join("/", @$unassigned_solexa),"\n";
}
