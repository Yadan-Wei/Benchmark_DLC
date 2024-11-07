#!/bin/bash

set -ex;


export TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
export JOB_DIR="$(pwd)"

export MODEL_DATASET_DIR=$DATA_DIR/$MODEL
export DATA_SOURCE="cc12m"


export LOG_FILE_NAME="train_${MODEL}_${TAG}_${INSTANCE_TYPE}_${NUM_NODES}nodes_${TIMESTAMP}"

# ===================================================
# Get Dataset
# =================================================== 

JOB_ID_1=$(sbatch --parsable --partition=${PARTITION} --output ${METRICS_DIR_PATH}/data_${LOG_FILE_NAME}_%j.out processing_data.sbatch)

# ===================================================
# Model Dependency Installation and Training
# ===================================================

echo "Check training logs at: ${METRICS_DIR_PATH}"
# --nodes=2 # number of nodes to use, 2 p4d(e) = 16 A100 GPUs
JOB_ID_2=$(sbatch --parsable --dependency=afterok:$JOB_ID_1 --kill-on-invalid-dep=yes --nodes=$NUM_NODES --partition=${PARTITION} --output ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.out distributed_training.sbatch)


# ===================================================
# Process Benchmarking Result
# ===================================================

JOB_ID_3=$(sbatch --parsable --dependency=afterok:$JOB_ID_2 --kill-on-invalid-dep=yes --partition=${PARTITION} --output ${METRICS_DIR_PATH}/process_${LOG_FILE_NAME}_%j.out process_openclip_results.sh $JOB_ID_2)
echo ${JOB_ID_3} >> ${METRICS_DIR_PATH}/process_res_job_list.txt


