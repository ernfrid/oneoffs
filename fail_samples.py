#!/usr/bin/env python

import sys

def main():
    header = None
    num_failed = 0
    for line in sys.stdin:
        if header is None:
            header = line.rstrip().split('\t')
            sys.stdout.write('\t'.join(header + ['Failure_Reason']))
            sys.stdout.write('\n')
        else:
            fields = dict(zip(header, line.rstrip().split('\t')))
            reason = fail_sample(fields)
            if reason is not None:
                sys.stdout.write('\t'.join([ fields[x] for x in header]))
                sys.stdout.write('\t{0}\n'.format(reason))
                num_failed = num_failed + 1

    sys.stderr.write('{0} failed QC\n'.format(num_failed))

def fail_sample(fields):
    reason = list()
    if float(fields['Mean_Coverage']) < 20:
        reason.append('Coverage')
    if float(fields['Freemix']) > 0.05:
        reason.append('Freemix')
    if float(fields['Picard_Mismatch_Rate']) > 0.05:
        reason.append('mismatch_rate')
    if reason:
        return ','.join(reason)
    else:
        return None

if __name__ == '__main__':
    main()
