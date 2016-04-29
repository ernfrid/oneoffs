#!/bin/bash

args=("$@")
times=${args[0]} #number of times to run the command
queue=${args[1]}
jobname=${args[2]} #what to call these jobs
hostname=${args[3]} #what host to use
cmd=${args[*]:4}

#bsub initial job
bsub -N -u dlarson@genome.wustl.edu -q $queue -m "$hostname" -J $jobname.1 $cmd

for ((i=2;i<=times;i++)); do
    prev=$((i - 1))
    bsub -N -u dlarson@genome.wustl.edu -q $queue -m "$hostname" -J $jobname.$i -w "done($jobname.$prev)" $cmd
done
exit 0
