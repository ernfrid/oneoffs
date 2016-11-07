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

class ValidateBwa(unittest.TestCase):
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

        
if __name__ == '__main__':
    unittest.main()
