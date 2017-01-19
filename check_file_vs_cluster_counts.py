#!/usr/bin/env python

import csv
import sys
from collections import defaultdict

class Flagstat(object):
    def __init__(self, file_path):
        self.file_path = file_path
        self._parse()

    def _parse(self):
        with open(self.file_path) as flagstat:
            self._values = [int(x.split(' ')[0]) for x in flagstat]

    @property
    def read1(self):
        """Number of read1 reads. Primary only."""
        return self._values[6]

    @property
    def read2(self):
        """Number of read2 reads. Primary only."""
        return self._values[7]

class CountsFromDb(object):
    def __init__(self, filename):
        self.total_expected = defaultdict(int);
        with open(filename, 'r') as csvfile:
            reader = csv.reader(csvfile, delimiter='\t')
            for row in reader:
                self.total_expected[row[1]] += int(row[2])

if __name__ == '__main__':
    expected_file = '/gscmnt/gc2802/halllab/sv_aggregate/CEPH/realigned_BAMs/notes/UtahDataCEPH.instrument_data_ids.cluster_counts.sample.txt'
    expected_counts = CountsFromDb(expected_file)
    flagstat_sample = sys.argv[1]
    flagstat = Flagstat(sys.argv[2])
    sys.stderr.write("read1: {0} expected: {1}\n".format(flagstat.read1, expected_counts.total_expected[flagstat_sample]))
    if flagstat.read1 == flagstat.read2 and flagstat.read1 == expected_counts.total_expected[flagstat_sample]:
        print "{0} ok".format(flagstat_sample)
    else:
        print "{0} failed".format(flagstat_sample)
        sys.exit(1)
