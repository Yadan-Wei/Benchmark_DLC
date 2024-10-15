#!/bin/bash

set -ex;

export INSTANCE_TYPE="p4d"
export TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
export JOB_DIR="$(pwd)"
export NUM_NODES=2
export MODEL_DATASET_DIR=$DATA_DIR/$MODEL
export DATA_SOURCE="cc12m"


case "${INSTANCE_TYPE}" in
    p4d)
    PARTITION="queue1"
    ;;
    p5)
    PARTITION="queue2"
    ;;
    *)
    PARTITION="queue1"
    ;;
esac

export LOG_FILE_NAME="train_${MODEL}_${TAG}_${INSTANCE_TYPE}_${NUM_NODES}nodes_${TIMESTAMP}"

# ===================================================
# Get Dataset
# =================================================== 

JOB_ID_1=$(sbatch --partition=${PARTITION} --output ${METRICS_DIR_PATH}/data_${LOG_FILE_NAME}_%j.out processing_data.sbatch| awk '{print $4}')

# ===================================================
# Model Dependency Installation and Training
# ===================================================

echo "Check training logs at: ${METRICS_DIR_PATH}"
# --nodes=2 # number of nodes to use, 2 p4d(e) = 16 A100 GPUs
JOB_ID_2=$(sbatch --dependency=afterok:$JOB_ID_1 --kill-on-invalid-dep=yes --nodes=$NUM_NODES --partition=${PARTITION} --output ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.out distributed_training.sbatch | awk '{print $4}')


# ===================================================
# Process Benchmarking Result
# ===================================================

sbatch --dependency=afterok:$JOB_ID_2 --kill-on-invalid-dep=yes --partition=${PARTITION} --output ${METRICS_DIR_PATH}/process_${LOG_FILE_NAME}_%j.out process_openclip_results.sh $JOB_ID_2


