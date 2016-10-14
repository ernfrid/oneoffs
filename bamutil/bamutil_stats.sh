#!/bin/bash

BAM=$1
BASE=${BAM##*/}
OUTPUT=$BASE.stats

BAMUTIL=/gscmnt/gc2801/analytics/dlarson/BIO-2028/bamUtil_1.0.13/bamUtil/bin/bam

# Exclusions:
#      4 - Read unmapped. This also excludes clipped bases
#    256 - Not primary alignment. We probably don't need this, but let's be safe
#    512 - Read fails vendor quality checks. We probably don't need this, but let's be safe
#   1024 - Read is a duplicate.
#   2048 - Supplementary alignment. Excluding these because ALT hits that don't have an alignment on the primary backbone will not be marked supplementary. Including these would double count reads with hits on both the alts and the primary backbone
#   3844 - Total

FLAGS=3844 # See above

# Note that --phred give us what we want but on STDERR. WHY!?!
# Note also that bases mapped where the reference is an N are not excluded.
# See http://genome.sph.umich.edu/wiki/BamUtil:_stats
$BAMUTIL stats --noPhoneHome --in $BAM --phred --excludeFlags $FLAGS 2> $OUTPUT
