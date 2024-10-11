#!/bin/bash

#SBATCH --job-name=openclip-data # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1