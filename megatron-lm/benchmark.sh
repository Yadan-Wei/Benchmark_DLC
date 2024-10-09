
#!/bin/bash

set -ex;


# dynamic environment settings
# export PORT=$(comm -23 <(seq 50000 65536  | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
# export CPU_COUNT=${SLURM_CPUS_PER_TASK}
export TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
export JOB_DIR="$(pwd)"
# export DATASET_DIR="/fsx/dataset"
# export MODEL_NAME="megatron"
export INSTANCE_TYPE="p4d"
export NUM_NODES=2
# export IMAGE_TAG="2.4.0-gpu-py311-cu124-ubuntu22.04-ec2"
export MODEL_DATASET_DIR=$DATA_DIR/$MODEL

# ===================================================
# Get Dataset
# ===================================================

if [ ! -d "${MODEL_DATASET_DIR}" ]; then
    mkdir -p ${MODEL_DATASET_DIR}
    aws s3 sync s3://aws-conda-benchmark-datasets/megatron ${MODEL_DATASET_DIR}
fi

export LOG_FILE_NAME="train_${MODEL}_${TAG}_${INSTANCE_TYPE}_${NUM_NODES}nodes_${TIMESTAMP}"

# # ===================================================
# # Model Dependency Installation and Training
# # ===================================================
# echo "Check training logs at: ${METRICS_DIR_PATH}"
# # cd $METRICS_DIR_PATH
# JOB_ID=$(sbatch --output ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.out --error ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.err distributed_training.sbatch | awk '{print $4}')

# if [ -n "$JOB_ID" ]; then
#     echo "Job submitted with ID: $JOB_ID"
# else
#     echo "Failed to submit job"
#     exit 1
# fi



# ===================================================
# Process Benchmarking Result
# ===================================================

# sbatch --kill-on-invalid-dep=afterok:$JOB_ID --kill-after \
#         --wrap="python process_megatron_results.py \
#     --log_file ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_${JOB_ID}.out \
#     --metrics_dir_path ${METRICS_DIR_PATH} \
#     --num_nodes ${NUM_NODES}"

python process_megatron_results.py \
    --log_file ${METRICS_DIR_PATH}/train_megatron-lm_2.4.0-gpu-py311-cu124-ubuntu22.04-ec2_p4d_2nodes_2024-10-08-23-57-18_286.out \
    --metrics_dir_path ${METRICS_DIR_PATH} \
    --num_nodes ${NUM_NODES}


