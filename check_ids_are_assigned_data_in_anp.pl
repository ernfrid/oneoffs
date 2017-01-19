#!/usr/bin/env genome-perl

use strict;
use warnings;

use Genome;
use Set::Scalar;

# Take an anp id on the command line 
my ($anp) = shift @ARGV;
my $anp_obj = Genome::Config::AnalysisProject->get($anp);
print STDERR "Found ", $anp_obj->name, " for $anp\n";

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

my $query_set = Set::Scalar->new(map { chomp; $_; } <>);

my $query_set_unique = $query_set - $used_set;

if ($query_set_unique && !$query_set_unique->is_empty) {
    print "The following ids were not assigned to models in $anp:\n";
    print join("/", @$query_set_unique),"\n";
}
