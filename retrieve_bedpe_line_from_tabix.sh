#!/bin/bash

set -eo pipefail

BEDPE="$1"
CHR="$2"
POS="$3"
ID="$4"

TABIX=/gscmnt/gc2719/halllab/bin/tabix

${TABIX} ${BEDPE} ${CHR}:${POS}-${POS} | awk "\$7 == \"${ID}\" || \$13 == \"${ID}\" || \$16 == \"${ID}\""
