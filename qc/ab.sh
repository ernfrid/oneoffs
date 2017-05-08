#!/bin/bash

set -eo pipefail

INVCF=$1
countfile=$2

zcat $INVCF \
| /gscmnt/gc2719/halllab/bin/bcftools view -m2 -M2 -v snps --no-update - \
| python ~/src/oneoffs/add_ab_both.py \
| /gscmnt/gc2719/halllab/bin/bcftools query -f '%REF\t%FIRST_ALT\t%FILTER\t%INFO/AF\t%INFO/AC\t%INFO/AB\t%INFO/AB_HOM\t%INFO/VQSLOD\n' \
| python ~/src/oneoffs/qc/classify_titv.py \
| bgzip -c > $countfile
 
