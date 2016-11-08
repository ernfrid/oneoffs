#!/usr/bin/env python

import unittest
import validate_header

class UtilTests(unittest.TestCase):
    def test_create_field_dict(self):
        test_line = '@SQ\tSN:T:G\tSL:2\n'
        self.assertEqual(validate_header.create_field_dict(test_line), { 'SN': 'T:G', 'SL': '2' })

    def test_create_field_set(self):
        test_line = '@SQ\tSN:T:G\tPI:0\tSL:2\tDT:blah\n'
        self.assertEqual(validate_header.create_field_set(test_line), frozenset(['SN:T:G', 'SL:2' ]))

class ValidateBwaTests(unittest.TestCase):
    def test_call(self):
        obj = validate_header.ValidateBwa()
        with self.assertRaises(AssertionError):
            obj.verdict()

        valid_line = '@RG\tID:bwamem.7\tPN:bwamem\tVN:0.7.15-r1140\tCL:bwa mem -Y -K 100000000 fastq\n'
        obj(valid_line)
        obj.verdict() #this shouldn't raise
        invalid_line = '@RG\tID:bwamem.7\tPN:bwamem\tVN:0.7.15-r1140\tCL:bwa mem -Y -K 10000000 fastq\n'
        with self.assertRaises(AssertionError):
            obj(invalid_line)
            obj.verdict()

        obj = validate_header.ValidateBwa()
        invalid_line2 = '@RG\tID:bwamem.7\tPN:bwamem\tVN:0.7.15-r1140\tCL:bwa mem -K 100000000 fastq\n'
        with self.assertRaises(AssertionError):
            obj(invalid_line2)
            obj.verdict()

        obj = validate_header.ValidateBwa()
        invalid_line3 = '@RG\tID:bwamem.7\tPN:bwamem\tVN:0.7.12\tCL:bwa mem -Y -K 1000000000\n'
        with self.assertRaises(AssertionError):
            obj(invalid_line3)
            obj.verdict()

class ValidateSqTests(unittest.TestCase):
    def setUp(self):
        self.ref_file = 'test_data/ref/all_sequences.fa'
        self.obj = validate_header.ValidateSq(self.ref_file)

    def test_init_and_parse(self):
        expected_names = set(['chr1', 'chr2', 'HLA-DRB1*15:03:01:02', 'HLA-DRB1*16:02:01'])
        alt_names = set(['HLA-DRB1*15:03:01:02', 'HLA-DRB1*16:02:01'])
        self.assertEqual(self.obj.expected_names, expected_names)
        self.assertEqual(self.obj.alt_names, alt_names)

    def test_valid_non_alt(self):
        valid_non_alt = '@SQ\tLN:2222\tSN:chr2'
        self.obj(valid_non_alt)
        self.assertIsNone(self.obj.verdict()) #shouldn't throw

    def test_valid_alt(self):
        valid_alt = '@SQ\tLN:2222\tSN:HLA-DRB1*15:03:01:02\tAH:*'
        self.obj(valid_alt)
        self.assertIsNone(self.obj.verdict()) #shouldn't throw

    def test_invalid_alt(self):
        invalid_alt = '@SQ\tSN:HLA-DRB1*15:03:01:02\tLN:2222'
        with self.assertRaises(AssertionError):
            self.obj(invalid_alt)
            self.obj.verdict()

    def test_invalid_non_alt(self):
        invalid_non_alt = '@SQ\tSN:chr1\tAH:*\tLN:1'
        with self.assertRaises(AssertionError):
            self.obj(invalid_non_alt)
            self.obj.verdict()

class ValidateReadgroupsTests(unittest.TestCase):
    def setUp(self):
        self.readgroupfiles = ['test_data/readgroupfiles/rg1', 'test_data/readgroupfiles/rg2']
        self.obj = validate_header.ValidateReadgroups(self.readgroupfiles)

    def test_init_and_parse(self):
        rg2_l1_set = validate_header.create_field_set('@RG\tID:1\tDT:2013\tLB:LIB35\tSM:sample')
        rg1_l1_set = validate_header.create_field_set('@RG\tID:A\tDT:2013\tLB:LIB30\tSM:sample')
        rg1_l2_set = validate_header.create_field_set('@RG\tID:B\tDT:2013\tLB:LIB30\tSM:sample')

        expected_valid_lines = set([rg2_l1_set, rg1_l1_set, rg1_l2_set])
        self.assertEqual(expected_valid_lines, self.obj.expected_lines)

    def test_valid_lines(self):
        lines = (
                '@RG\tID:1\tDT:2013\tLB:LIB35\tSM:sample', 
                '@RG\tID:A\tDT:2013\tLB:LIB30\tSM:sample',
                '@RG\tID:B\tDT:2013\tLB:LIB30\tSM:sample'
                )
        for line in lines:
            self.obj(line)
        self.assertIsNone(self.obj.verdict())

    def test_invalid_line(self):
        line = '@RG\tID:C\tDT:2013\tLB:LIB30\tSM:sample'
        self.obj(line)
        with self.assertRaises(AssertionError):
            self.obj.verdict()

    def test_missing_line(self):
        line = '@RG\tID:1\tDT:2013\tLB:LIB35\tSM:sample'
        self.obj(line)
        with self.assertRaises(AssertionError):
            self.obj.verdict()
        
if __name__ == '__main__':
    unittest.main()
