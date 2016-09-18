#!/usr/bin/env python

import sys
import json
from math import sqrt

def mean_and_sd(iterable):
    mean = sum(iterable) / len(iterable)
    sd = 0
    if len(iterable) > 1:
        sd = sqrt(sum([ (x - mean)**2 for x in iterable]) / (len(iterable) - 1))
    return (mean, sd)

class JobMetricAccumulator:
    def __init__(self):
        self.cpu = list()
        self.ram = list()
        self.wall = list()

    def process_json(self, json):
        self.cpu.append(json['CpuUsed'] / 60.0)
        self.ram.append(json['MaxMem'] / 1000.0)
        self.wall.append(json['RunTime'] / 60.0)

    def __str__(self):
        results = list()
        means_and_sd = map(mean_and_sd, (self.wall, self.cpu, self.ram))
        for x in means_and_sd:
            results.append(x[0])
            results.append(x[1])
        return "Wall(m): {0} +/- {1}\nCPU(m): {2} +/- {3}\nRAM(M): {4} +/- {5}\n".format(*results)

accumulator = JobMetricAccumulator()

doc = json.load(sys.stdin)
for job in doc:
    accumulator.process_json(job)

print accumulator
