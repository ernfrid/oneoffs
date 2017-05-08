#!/bin/bash

set -xeo pipefail

INVCF=$1
# THESE ARE IN FAM/PED file order
KID=$2
DAD=$3
MOM=$4
countfile=$5

# TODO
# Update to calculate MIEs on the fly


zcat $INVCF \
| /gscmnt/gc2719/halllab/bin/bcftools view -s ${KID},${DAD},${MOM} --no-update - \
| /gscmnt/gc2719/halllab/bin/bcftools view -g ^miss --no-update - \
| /gscmnt/gc2719/halllab/bin/bcftools query -f '%TYPE\t%FILTER\t%INFO/AF\t%INFO/AC\t%INFO/VQSLOD[\t%GT]\n' \
| grep "/1"  \
| python ~/src/oneoffs/qc/classify_mie.py \
| sort -k1,6 \
| bedtools groupby -g 1,2,3,4,5,6 -c 1 -o count \
| sed "s/^/${KID}:${DAD}:${MOM}\t/" \
| bgzip -c > $countfile
 
