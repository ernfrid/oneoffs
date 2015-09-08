#!/usr/bin/perl

use strict;
use warnings;

use Genome;

# function to take advantage of what we know about this project's sample names
# never ever extrapolate to other projects
sub finseq_subject_name_from_sample_name {
    my $name = shift;
    my ($individual) = $name =~ /(H_O[YS]-.+)-.+$/;
    unless($individual) {
        die "Unable to identify individual name from subject name\n";
    }
    return $individual;
}

#clean sample_names from stdin
my @sample_names = grep { defined $_ && $_ ne '' } map { chomp $_; finseq_subject_name_from_sample_name($_) } <>;
my %sample_name_requested = map { $_ => 1 } @sample_names;

# If true sample names and not individual names then we will need to do something like the following
# The Genome::Model->get line below will also need to be modified to look for subjects matching these individuals
#my @individuals = map { $_->individual } Genome::Sample->get(name => \@sample_names);
#@individuals = grep {defined $_ && $_ ne ''} @individuals;

# Below is the FinMetSeq Exome Analysis Project
my $anp = Genome::Config::AnalysisProject->get('95d17b80014a403da1f65f077b7e42b4');

# Below is the Processing Profile for the FinMetSeq Exome Project
my $pp = Genome::ProcessingProfile->get('90e070e59516450c860a7d9bde3d13f7');

my @models = Genome::Model->get(analysis_project => $anp, processing_profile => $pp, 'subject.name' => \@sample_names);
my @builds;
for my $model (@models) {
    my $build = $model->last_succeeded_build;
    if($build) {
        push @builds, $build;
    }
    else {
        warn "Unable to find succeeded build for model ", $model->name,"\n";
    }
}

#my @builds = map { $_->last_succeeded_build } @models;
for my $build (@builds) {
    delete $sample_name_requested{$build->subject->name};
    print join("\t", $build->id, $build->merged_alignment_result->bam_path), "\n";
}

for my $sample (keys %sample_name_requested) {
    print STDERR "Missing $sample\n";
}
