#!/bin/bash

args=("$@")
times=${args[0]} #number of times to run the command
jobname=${args[1]} #what to call these jobs
hostname=${args[2]} #what host to use

echo "times: $times, jobname: $jobname, hostname: $hostname, command: ${args[*]:3}"
