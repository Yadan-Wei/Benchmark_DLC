#!/bin/bash

export REGISTRY="763104351884.dkr.ecr.us-west-2.amazonaws.com"
export REPO="pytorch-training"
export TAG="2.4.0-gpu-py311-cu124-ubuntu22.04-ec2"
export IMAGE="${REGISTRY}/${REPO}:${TAG}"
export DATA_DIR="/fsx/dataset"
export IMAGE_DIR="$(pwd)/images"
export METRICS_DIR_PATH="$(pwd)/logs"
export INSTANCE_TYPE="p4d" # p5, m5 for arm64 we may need to add a new queue in pcluster

export NUM_NODES=2

export MODELS=(
        #"megatron-lm",
        "openclip"
        )