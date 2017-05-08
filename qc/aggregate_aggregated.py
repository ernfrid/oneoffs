#!/usr/bin/env python
from __future__ import division
import sys

aggregate_results = dict()

if __name__ == '__main__':
    for line in sys.stdin:
        vartype, filt, af, ac, vqslod, mie, none = line.rstrip().split('\t')
        keytuple = (vartype, filt, af, ac, vqslod)
        if keytuple not in aggregate_results:
            aggregate_results[keytuple] = [ 0, 0 ]
        aggregate_results[keytuple][0] += int(mie)
        aggregate_results[keytuple][1] += int(none)

    for key in aggregate_results:
        mie = aggregate_results[key][0]
        none = aggregate_results[key][1]
        print '\t'.join(key + ( str(mie), str(none), str(mie / (mie + none)) ))
