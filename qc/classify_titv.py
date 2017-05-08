#!/usr/bin/env python

import sys

def classify(ref, alt):
    classification = 'Transversion'
    if (
            (ref == 'A' and alt == 'G') or
            (ref == 'G' and alt == 'A') or
            (ref == 'T' and alt == 'C') or
            (ref == 'C' and alt == 'T')
            ):
        classification = 'Transition'
    return classification

if __name__ == '__main__':
    for line in sys.stdin:
        fields = line.rstrip().split('\t')
        assert(fields[0] in ('A', 'C', 'G', 'T') and fields[1] in ('A', 'C', 'G', 'T'))
        classification = classify(fields[0], fields[1])
        print '\t'.join(fields[2:] + [classification])
