#!/usr/bin/env python

import sys
import argparse
from itertools import ifilter

class ReaderException(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

class StatsReader(object):
    def __init__(self, handle):
        self.handle = handle
        self.num_lines = 0

    def __iter__(self):
        '''Read first two lines'''
        header = [ self.handle.next() for i in xrange(3) ]
        return self

    def _validate_header(self, header):
        self._validate_first_line(header[0])
        self._validate_second_line(header[1])
        self._validate_header_line(header[2])

    @staticmethod
    def _validate_first_line(line):
        if not line.startswith('Number of records read = '):
            raise ReaderException('Invalid first line: {0}'.format(line.rstrip()))
    
    @staticmethod
    def _validate_second_line(line):
        if not line.startswith('\n'):
            raise ReaderException('Non-blank second line: {0}'.format(line.rstrip()))

    @staticmethod
    def _validate_header_line(line):
        if not line == 'Phred	Count\n':
            raise ReaderException('Invalid header line: {0}'.format(line.rstrip()))

    def next(self):
        try:
            line = self.handle.next()
        except StopIteration as e:
            if self.num_lines != 94:
                raise ReaderException('Invalid number of lines.')
            else:
                raise
        self.num_lines += 1
        try:
            phred, count = line.rstrip().split('\t')
        except ValueError as e:
            raise ReaderException('Invalid number of columns.')
        return int(phred), int(count)

class BaseCountAccumulator(object):
    def __init__(self, min_base_quality=0):
        self.min_base_quality = min_base_quality

    def __call__(self, iterable):
        return sum(map(lambda x: x[1], ifilter( lambda x: x[0] >= self.min_base_quality, iterable)))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Total up the output of bamUtil's summary output (expected to be run with ONLY the --phred option and not --basic or --qual)")
    parser.add_argument('-b','--min-base-quality', default=0, type=int)
    args = parser.parse_args()
    
    try:
        reader = StatsReader(sys.stdin)
        accumulator = BaseCountAccumulator(args.min_base_quality)
        sys.stdout.write(str(accumulator(reader)))
        sys.stdout.write('\n')
    except ReaderException as e:
        sys.stderr.write(str(e).strip("'"))
        sys.stderr.write('\n')
        sys.exit(1)

