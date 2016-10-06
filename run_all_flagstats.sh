#!/bin/bash

set -euo pipefail

SAMTOOLS=samtools1.2


for BAM in $@; do
    echo $BAM

    #Whole file
     $SAMTOOLS flagstat $BAM > $BAM.flagstat

    ##Supplementary only
     $SAMTOOLS view -T /gscmnt/gc2802/halllab/aregier/jira/BIO-1875/b38_ref/all_sequences.fa -hu -f 2048 $BAM | $SAMTOOLS flagstat - > $BAM.flagstat_supp

    ##-----Supplementary Only, Both Mapped-----
     $SAMTOOLS view -T /gscmnt/gc2802/halllab/aregier/jira/BIO-1875/b38_ref/all_sequences.fa -hu -F 12 -f 2048 $BAM | $SAMTOOLS flagstat - > $BAM.flagstat_supp_both_mapped

    ##both mapped, nonsupplementary
     $SAMTOOLS view -T /gscmnt/gc2802/halllab/aregier/jira/BIO-1875/b38_ref/all_sequences.fa -hu -F 2060 $BAM | $SAMTOOLS flagstat - > $BAM.flagstat_both_mapped_non_supp

    ##-----Orphan, mapped-end-----
     $SAMTOOLS view -T /gscmnt/gc2802/halllab/aregier/jira/BIO-1875/b38_ref/all_sequences.fa -hu -F 2052 -f 8 $BAM | $SAMTOOLS flagstat - > $BAM.flagstat_orphan_mapped_end_non_supp

    ##-----Orphan, unmapped-end-----
     $SAMTOOLS view -T /gscmnt/gc2802/halllab/aregier/jira/BIO-1875/b38_ref/all_sequences.fa -hu -F 2056 -f 4 $BAM | $SAMTOOLS flagstat - > $BAM.flagstat_orphan_unmapped_end_non_supp
done
