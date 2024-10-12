
#!/bin/bash

set -ex;


export TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
export JOB_DIR="$(pwd)"
export INSTANCE_TYPE="p4d"
export NUM_NODES=2
export MODEL_DATASET_DIR=$DATA_DIR/$MODEL

# ===================================================
# Get Dataset
# ===================================================

if [ ! -d "${MODEL_DATASET_DIR}" ]; then
    mkdir -p ${MODEL_DATASET_DIR}
    aws s3 sync s3://aws-conda-benchmark-datasets/megatron ${MODEL_DATASET_DIR}
fi

export LOG_FILE_NAME="train_${MODEL}_${TAG}_${INSTANCE_TYPE}_${NUM_NODES}nodes_${TIMESTAMP}"

# ===================================================
# Model Dependency Installation and Training
# ===================================================
echo "Check training logs at: ${METRICS_DIR_PATH}"
# --nodes=2 # number of nodes to use, 2 p4d(e) = 16 A100 GPUs
JOB_ID=$(sbatch --nodes=$NUM_NODES  --output ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.out distributed_training.sbatch | awk '{print $4}')

if [ -n "$JOB_ID" ]; then
    echo "Training Job submitted with ID: $JOB_ID"
else
    echo "Failed to submit job"
    exit 1
fi


# ===================================================
# Process Benchmarking Result
# ===================================================

sbatch --dependency=afterok:$JOB_ID --kill-on-invalid-dep=yes --output ${METRICS_DIR_PATH}/process_${LOG_FILE_NAME}_%j.out process_megatron_results.sh $JOB_ID


