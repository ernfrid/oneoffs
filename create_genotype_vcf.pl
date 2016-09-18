#!/usr/bin/env genome-perl

use strict;
use warnings;

use Data::Dumper;

use Genome;
use Genome::Qc::Command::ImportGenotypeVcfFile;

my $vcf = shift;
my $build = Genome::Model::Build->get(q{8741b5363c634ee19fad676157a132de});

my $object = Genome::Qc::Command::ImportGenotypeVcfFile->execute(
    genotype_vcf_file => $vcf,
    reference_sequence_build => $build,
    requestor => $build,
);

UR::Context->commit();
print Dumper $object->output_result;


