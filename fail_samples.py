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
            sys.stdout.write('\t'.join([ fields[x] for x in header]))
            if reason is not None:
                sys.stdout.write('\t{0}\n'.format(reason))
                num_failed = num_failed + 1
            else:
                sys.stdout.write('\tPass\n')
    sys.stderr.write('{0} failed QC\n'.format(num_failed))

def fail_sample(fields):
    reason = list()
    #if float(fields['New_Haploid_Coverage']) < 19.5:
    if float(fields['Haploid_Coverage']) < 19.5:
        reason.append('Coverage')
    if float(fields['Freemix']) >= 0.05:
        reason.append('Freemix')
    if ((float(fields['Read1_Picard_Mismatch_Rate']) >= 0.05) or 
            (float(fields['Read2_Picard_Mismatch_Rate']) >= 0.05)):
        reason.append('mismatch_rate')
    if (float(fields['Flagstat_Percentage_Interchromosomal_Pair']) >= 0.05):
        reason.append('Interchromosomal')
    if ((float(fields['Picard_Percent_Reads_Aligned']) * 100) - float(fields['Flagstat_Percentage_Proper_Pair'])) >= 5.0:
        reason.append('Discordant')
    if reason:
        return ','.join(reason)
    else:
        return None

if __name__ == '__main__':
    main()
