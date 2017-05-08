#!/bin/bash

set -xeo pipefail

INVCF=$1
# THESE ARE IN FAM/PED file order
KID=$2
DAD=$3
MOM=$4
countfile=$5

zcat $INVCF \
| /gscmnt/gc2719/halllab/bin/bcftools view -s ${KID},${DAD},${MOM} --no-update - \
| /gscmnt/gc2719/halllab/bin/bcftools view -g ^miss --no-update - \
| python ~/src/oneoffs/add_ab_both.py \
| /gscmnt/gc2719/halllab/bin/bcftools query -f '%TYPE\t%FILTER\t%INFO/AF\t%INFO/AC\t%INFO/AB\t%INFO/AB_HOM\t%INFO/VQSLOD[\t%GT]\n' \
| grep "/1"  \
| python ~/src/oneoffs/qc/classify_mie.py \
| sort -k1,8 \
| bedtools groupby -g 1,2,3,4,5,6,7,8 -c 1 -o count \
| sed "s/^/${KID}:${DAD}:${MOM}\t/" \
| bgzip -c > $countfile
 
