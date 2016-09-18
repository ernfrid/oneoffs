#!/usr/bin/env python

# This is modeled after https://github.com/genome/diagnose_dups/blob/master/test-data/generate_integration_test_sam.py

header = """@HD	VN:1.3	SO:coordinate
@SQ	SN:1	LN:249250621
@SQ	SN:2	LN:243199373"""

sam_lines = (
        header,
        # Program calculates depth above a certain base quality cutoff as well as sum of base qualities at a given position over a cutoff
        # It should ignore supplementary, duplicate, etc alignments
        # It should ignore unaligned bases (hardclipped/softclipped/gaps/insertions) in coverage and bq sum calculations

        # This is a fully aligned read, non-duplicate and non-secondary. It should count at all positions. A is BQ=65-33=32; F is BQ=37
        "r1	163	1	15729	60	5M	=	16153	575	CAGGG	AAFFF",
        # Fails vendor qc
        "r2	675	1	15729	60	5M	=	16153	575	CAGGG	AAFFF",
        # Duplicate
        "r3	1187	1	15729	60	5M	=	16153	575	CAGGG	AAFFF",
        # Secondary
        "r4	419	1	15729	60	5M	=	16153	575	CAGGG	AAFFF",
        # Supplementary: These are currently included :
        "r5	2211	1	15729	60	5M	=	16153	575	CAGGG	AAFFF",

        # Orphan: These will be excluded by latest code:
        "r9	169	1	15729	60	5M	=	16153	575	CAGGG	AAFFF",

        # Soft clip some trailing bases
        "r6	163	1	15729	60	3M2S	=	16153	575	CAGGG	AAFFF",

        # Delete the middle base
        "r7	163	1	15729	60	2M1D2M	=	16153	575	CAGG	AAAB",

        # Insertion
        "r8	163	1	15729	60	1M3I1M	=	16153	575	CAGGG	AAFFF",
        )

print '\n'.join(sam_lines)
