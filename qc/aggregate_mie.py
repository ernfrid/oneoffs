#!/usr/bin/env python

import sys

aggregate_results = dict()

if __name__ == '__main__':
    for line in sys.stdin:
        trio, vartype, filt, af, ac, vqslod, cls, count = line.rstrip().split('\t')
        vqslod = str(round(float(vqslod), 1))
        keytuple = (vartype, filt, af, ac, vqslod)
        if keytuple not in aggregate_results:
            aggregate_results[keytuple] = { 'MIE': 0, 'NONE': 0 }
        aggregate_results[keytuple][cls] += int(count)

    for key in aggregate_results:
        print '\t'.join(key + ( str(aggregate_results[key]['MIE']), str(aggregate_results[key]['NONE'])))
