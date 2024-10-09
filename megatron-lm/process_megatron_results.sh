#!/bin/bash

set -ex

JOB_ID=$1

python process_megatron_results.py \
    --log_file ${METRICS_DIR_PATH}/${LOG_FILE_NAME}_${JOB_ID}.out \
    --metrics_dir_path ${METRICS_DIR_PATH} \
    --num_nodes ${NUM_NODES}