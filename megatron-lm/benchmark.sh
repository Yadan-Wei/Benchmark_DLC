
#!/bin/bash

set -ex;


export TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
export JOB_DIR="$(pwd)"
export MODEL_DATASET_DIR=$DATA_DIR/$MODEL

# case "${INSTANCE_TYPE}" in
#     p4d)
#     PARTITION="queue1"
#     ;;
#     p5)
#     PARTITION="queue2"
#     ;;
#     *)
#     PARTITION="queue1"
#     ;;
# esac

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
JOB_ID=$(sbatch --parsable  --nodes=$NUM_NODES  --partition=${PARTITION} --output ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.out distributed_training.sbatch)

if [ -n "$JOB_ID" ]; then
    echo "Training Job submitted with ID: $JOB_ID"
else
    echo "Failed to submit job"
    exit 1
fi


# ===================================================
# Process Benchmarking Result
# ===================================================

JOB_ID_2=$(sbatch --parsable --dependency=afterok:$JOB_ID --kill-on-invalid-dep=yes --output ${METRICS_DIR_PATH}/process_${LOG_FILE_NAME}_%j.out process_megatron_results.sh $JOB_ID)

echo ${JOB_ID_2} >> ${METRICS_DIR_PATH}/process_res_job_list.txt
