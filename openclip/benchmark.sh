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
    aws s3 sync s3://aws-conda-benchmark-datasets/cc3m ${MODEL_DATASET_DIR}/cc3m


    # # takes too long time to get data from source and process
    # wget https://storage.googleapis.com/conceptual_12m/cc12m.tsv
    # sed -i '1s/^/url\tcaption\n/' cc12m.tsv
    # img2dataset --url_list cc12m.tsv --input_format "tsv"\
    #      --url_col "url" --caption_col "caption" --output_format webdataset\
    #        --output_folder cc12m --processes_count 16 --thread_count 64 --image_size 256\
    #          --enable_wandb False

    
fi

export LOG_FILE_NAME="train_${MODEL}_${TAG}_${INSTANCE_TYPE}_${NUM_NODES}nodes_${TIMESTAMP}"

# ===================================================
# Model Dependency Installation and Training
# ===================================================
echo "Check training logs at: ${METRICS_DIR_PATH}"
# --nodes=2 # number of nodes to use, 2 p4d(e) = 16 A100 GPUs
JOB_ID=$(sbatch --nodes=$NUM_NODES --partition="queue1" --output ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.out --error ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_%j.err distributed_training.sbatch | awk '{print $4}')

if [ -n "$JOB_ID" ]; then
    echo "Training Job submitted with ID: $JOB_ID"
else
    echo "Failed to submit job"
    exit 1
fi
