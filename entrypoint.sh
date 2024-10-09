#!/bin/bash

set -ex

export REGISTRY="763104351884.dkr.ecr.us-west-2.amazonaws.com"
export REPO="pytorch-training"
export TAG="2.4.0-gpu-py311-cu124-ubuntu22.04-ec2"
export IMAGE="${REGISTRY}/${REPO}:${TAG}"
export DATA_DIR="/fsx/dataset"
export IMAGE_DIR="$(pwd)/images"
export METRICS_DIR_PATH="$(pwd)/logs"

MODELS=("megatron-lm")

# ===================================================
# pull image
# ===================================================

bash pull_image.sh

# ===================================================
# train model and generate json file
# ===================================================

for MODEL in "${MODELS[@]}"; do
    export MODEL
    cd $MODEL
    bash benchmark.sh
    cd ..
done

# ===================================================
# clean up
# ===================================================
