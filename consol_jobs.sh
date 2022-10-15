#!/bin/sh

jobIds=$(squeue --nohead --format %F)
jobIds=(${jobIds//$'\n'/:})
cmd1="sbatch --dependency=afterany:${jobIds} /data/src/PyHipp/ec2snapshot.sh"

echo $cmd1
eval $cmd1
