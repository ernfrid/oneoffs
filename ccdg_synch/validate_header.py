#!/usr/bin/env python

import re
import argparse
import sys

def create_field_dict(line):
    field_dict = dict()
    for field in line.rstrip().split('\t'): 
        if not field.startswith('@'):
            key, value = field.split(':', 1)
            field_dict[key] = value
    return field_dict

def create_field_set(line):
    field_set = set()
    for field in line.rstrip().split('\t'):
        if not field.startswith('@') and not field.startswith('DT:') and not field.startswith('PI:') and not field.startswith('DS:'):
            field_set.add(field)
    return frozenset(field_set)

class ValidateReadgroups(object):
    def __init__(self, readgroupfiles):
        self.invalid_lines = set()
        self.valid_lines = set()
        self.expected_lines = set()
        for rgfile in readgroupfiles:
            with open(rgfile, 'r') as f:
                for line in f:
                    self.expected_lines.add(create_field_set(line))
    def __call__(self, line):
        field_set = create_field_set(line)
        if field_set in self.expected_lines:
            self.valid_lines.add(line)
        else:
            print line,
            self.invalid_lines.add(line)

    def verdict(self):
        assert len(self.valid_lines) == len(self.expected_lines), 'Missing expected @RG lines'
        assert len(self.invalid_lines) == 0, 'Invalid @RG lines found'

class ValidateSq(object):
    def __init__(self, reference_path):
        self.invalid_ah = False
        self.invalid_name = False

        self.expected_names = self._parse_index_file(reference_path + '.fai')
        self.alt_names = self._parse_alt_file(reference_path + '.alt')

    def _parse_index_file(self, path):
        expected_names = set()
        with open(path, 'r') as f:
            for line in f:
                fields = line.rstrip().split('\t')
                expected_names.add(fields[0])
        return expected_names

    def _parse_alt_file(self, path):
        alt_names = set()
        with open(path, 'r') as f:
            for line in f:
                fields = line.rstrip().split('\t')
                if not line.startswith('@SQ'):
                    #It's not a normal name
                    alt_names.add(fields[0])
        return alt_names

    def __call__(self, line):
        field_dict = create_field_dict(line)
        seq_name = field_dict['SN']
        if seq_name in self.expected_names:
            has_ah = 'AH' in field_dict
            is_alt = seq_name in self.alt_names
            if (is_alt != has_ah):
                print 'Invalid AH tag for reference name: {0}'.format(seq_name)
                self.invalid_ah = True
        else:
            print 'Unexpected reference name: {0}'.format(seq_name)
            self.invalid_name = True


    def verdict(self):
        assert not self.invalid_ah, 'No AH tag found in on the @SQ record of an expected ALT'
        assert not self.invalid_name, 'Unexpected reference name detected in @SQ record'

class ValidateBwa(object):
    def __init__(self):
        self.found_bwa = False
        self.all_bwa_had_proper_params = True

    def __call__(self, line):
        field_dict = create_field_dict(line)
        if field_dict['ID'].startswith('bwa') and (field_dict['PN'] == 'bwa' or field_dict['PN'] == 'bwamem'):
            self.found_bwa = True

            self.all_bwa_had_proper_params = (self.all_bwa_had_proper_params and 
                    field_dict['VN'] == '0.7.15-r1140' and
                    ' -Y ' in field_dict['CL'] and
                    ' -K 100000000 ' in field_dict['CL'])

    def verdict(self):
        assert self.found_bwa, 'No bwa @PG entries found'
        assert self.all_bwa_had_proper_params, 'Improper bwa params (version, -Y or -K)'

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Validate a CCDG CRAM file header')
    parser.add_argument('readgroupfile', metavar='FILE', type=str, nargs='+', help='path to file containing all expected @RG lines')
    parser.add_argument('--ref', metavar='FILE', type=str, help='path to reference file to use for determining expected chromosome names and alts. Needs .alt and .fai file')
    args = parser.parse_args()

    rg_validator = ValidateReadgroups(args.readgroupfile)
    sq_validator = ValidateSq(args.ref)
    bwa_validator = ValidateBwa()
    def noop(x):
        pass

    validator_dict = {
            '@SQ': sq_validator,
            '@PG': bwa_validator,
            '@RG': rg_validator
            }

    for line in sys.stdin:
        v = validator_dict.get(line.split('\t')[0], noop)
        v(line)

    rv = 0
    for validator in validator_dict.values():
        try:
            validator.verdict()
        except AssertionError as e:
            rv = 1
            sys.stderr.write(str(e))
            sys.stderr.write('\n')

    sys.exit(rv)
