#!/bin/bash -ex

times=5
queue="hall-lab"
jobname="benchmark"
hostname=""

while getopts ":n:q:J:m:" opt; do
    case $opt in
        n)
            echo "Running command $OPTARG times" >&2
            times=$OPTARG
            ;;
        q)
            echo "Using queue $OPTARG" >&2
            queue=$OPTARG
            ;;
        J)
            echo "Using job name base $OPTARG" >&2
            jobname=$OPTARG
            ;;
        m)
            echo "Submitting to host $OPTARG" >&2
            hostname=$OPTARG
            ;;
        \?)
            echo "Unknown option -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            exit 1
            ;;
    esac
done

if [ $hostname == '' ]; then
    echo "Must specify a hostname with -m" >&2
    exit 1
fi

# Remove all processed arguments
shift $((OPTIND-1))
cmd=${@}

processors=`bhosts -w $hostname | sed 's/\s\+/	/g' | grep -v MAX | cut -f4`
echo "Requesting $processors processors on $hostname" >&2

#bsub initial job
bsub -N -u dlarson@genome.wustl.edu -n $processors -q $queue -m "$hostname" -J ${jobname}.1 $cmd

for ((i=2;i<=times;i++)); do
    prev=$((i - 1))
    bsub -N -u dlarson@genome.wustl.edu -n $processors -q $queue -m "$hostname" -J $jobname.$i -w "done($jobname.$prev)" $cmd
done
exit 0
