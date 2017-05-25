#!/bin/bash

set -ueo pipefail

BCFTOOLS="/gscmnt/gc2719/halllab/bin/bcftools"
vcfs=( "$@" )
export cohort=${vcfs[0]}
unset vcfs[0]

echo -e "Cohort\tSample\tGenotype\tType\tLength"

for vcf in "${vcfs[@]}"; do
    $BCFTOOLS view -f .,PASS $vcf \
        | $BCFTOOLS query -e 'INFO/SECONDARY=1' -f "[${cohort}\t%SAMPLE\t%GT\t%INFO/SVTYPE\t%INFO/SVLEN\n]" | grep -v '[0.]\/[0.]'
done
