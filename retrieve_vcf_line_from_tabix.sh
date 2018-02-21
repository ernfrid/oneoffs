#!/bin/bash

set -eo pipefail

VCF="$1"
CHR="$2"
POS="$3"
ID="$4"

TABIX=/gscmnt/gc2719/halllab/bin/tabix

${TABIX} ${VCF} ${CHR}:${POS}-${POS} | awk "\$3 == \"${ID}\""
