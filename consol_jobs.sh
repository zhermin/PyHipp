#!/bin/sh

latestjobid=$(squeue --nohead --format %F | tail -n 1)
cmd1="sbatch --dependency=afterok:${latestjobid}"
cmd1="${cmd1} /data/src/PyHipp/ec2snapshot.sh"

echo $cmd1
eval $cmd1
