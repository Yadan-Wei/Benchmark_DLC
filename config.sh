#!/bin/bash

export DATA_DIR="/fsx/dataset"
export IMAGE_DIR="$(pwd)/images"
export METRICS_DIR_PATH="$(pwd)/logs"
export INSTANCE_TYPE="p5" # p4d, p5, m5 for arm64 we may need to add a new queue in pcluster

export NUM_NODES=2

export MODELS=(
        "megatron-lm"
        "openclip"
        )

export IMAGE_SOURCE=(
        "DLC"
        "NGC"
)

# function to get tag, repo etc info of an image
get_image_info() {
    source="$1"
    case "$source" in
        DLC)
            export REGISTRY="763104351884.dkr.ecr.us-west-2.amazonaws.com"
            export REPO="pytorch-training"
            export TAG="2.4.0-gpu-py311-cu124-ubuntu22.04-ec2"
            ;;
        NGC)
            export REGISTRY="nvcr.io"
            export REPO="nvidia/pytorch"
            export TAG="24.05-py3"
            ;;
        *)
            echo "Invalid image source: $source"
            return 1
            ;;
    esac
}

# pick pcluster queue based on instance type 
# for arm we need to relaunch a cluster with arm instance
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

export PARTITION

export SEND_TO_CLOUDWATCH="True"

# https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel-24-05.html
# Ubuntu 22.04 including Python 3.10
# NVIDIA CUDA 12.4.1
# NVIDIA cuBLAS 12.4.5.8
# NVIDIA cuDNN 9.1.0.70
# NVIDIA NCCL 2.21.5
# NVIDIA RAPIDS™ 24.04
# rdma-core 39.0
# NVIDIA HPC-X 2.19
# OpenMPI 4.1.4+
# GDRCopy 2.3
# TensorBoard 2.9.0
# Nsight Compute 2024.1.14
# Nsight Systems 2024.2.1.106
# NVIDIA TensorRT™ 10.0.1.6
# Torch-TensorRT 2.4.0a0
# NVIDIA DALI® 1.37
# nvImageCodec 0.2.0.7
# MAGMA 2.6.2
# JupyterLab 2.3.2 including Jupyter-TensorBoard
# TransformerEngine 1.6
# PyTorch quantization wheel 2.1.2