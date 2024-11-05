#!/bin/bash

#SBATCH --job-name=openclip-data # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1
#SBATCH --ntasks=96
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1 # Number of CPU cores per task

set -ex

# https://github.com/rom1504/img2dataset/blob/main/dataset_examples/cc12m.md
# https://github.com/rom1504/img2dataset/blob/main/dataset_examples/cc3m.md


export DATA_SOURCE="cc12m"


if [ ! -d "${MODEL_DATASET_DIR}" ]; then
    mkdir -p ${MODEL_DATASET_DIR}   
fi

cd ${MODEL_DATASET_DIR}

case "${DATA_SOURCE}" in
    cc3m)
    if [ ! -d cc3m ]; then
        aws s3 sync s3://aws-conda-benchmark-datasets/cc3m ${MODEL_DATASET_DIR}/cc3m
    fi
    ;;
    cc12m)
    if [ ! -d cc12m ]; then
        aws s3 sync s3://aws-conda-benchmark-datasets/cc12m ${MODEL_DATASET_DIR}/cc12m
    fi
    ;;
esac


echo "Complete data processing"