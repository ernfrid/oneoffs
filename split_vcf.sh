#!/bin/bash

set -uoe pipefail

# This script based on: https://www.biostars.org/p/12535/
BCFTOOLS=bcftools1.2
OUTDIR=${2-""}

for file in "$@"; do
    for sample in `$BCFTOOLS view -h $file | grep "^#CHROM" | cut -f10-`; do
        $BCFTOOLS view -Oz -s $sample -o $OUTDIR/${sample}.vcf.gz $file
    done
done
