#!/usr/bin/perl

use strict;
use warnings;

use Genome;
use Data::Dumper;

my $id = 'cd447e07d79e47c5b6418b6493befdb1';
my $model_group = Genome::ModelGroup->get($id);

my @parts = Genome::ProjectPart->get(entity_id => [map $_->id, map $_->instrument_data, $model_group->models]);
my @projects = Genome::Project->get([map $_->project_id, @parts]);

for my $project (@projects) {
    print $project->id, "\n";
}

