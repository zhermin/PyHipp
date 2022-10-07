#!/bin/bash

# first job called from the day directory
# creates RPLParallel, Unity, and EDFSplit objects, and
# calls aligning_objects and raycast
sbatch /data/src/PyHipp/rplparallel-slurm.sh

# second set of jobs called from the day directory
sbatch /data/src/PyHipp/rs-1-slurm.sh
sbatch /data/src/PyHipp/rs-2-slurm.sh
sbatch /data/src/PyHipp/rs-3-slurm.sh
sbatch /data/src/PyHipp/rs-4-slurm.sh

