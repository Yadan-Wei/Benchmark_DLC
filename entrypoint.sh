#!/bin/bash

set -ex

# export REGISTRY="763104351884.dkr.ecr.us-west-2.amazonaws.com"
# export REPO="pytorch-training"
# export TAG="2.4.0-gpu-py311-cu124-ubuntu22.04-ec2"
# export IMAGE="${REGISTRY}/${REPO}:${TAG}"
# export DATA_DIR="/fsx/dataset"
# export IMAGE_DIR="$(pwd)/images"
# export METRICS_DIR_PATH="$(pwd)/logs"

# MODELS=(
#         #"megatron-lm",
#         "openclip"
#         )

. config.sh

# Make sure the dir exists
mkdir -p $METRICS_DIR_PATH
mkdir -p $DATA_DIR
mkdir -p $IMAGE_DIR

# clean up old log
rm -rf $METRICS_DIR_PATH/*

# ===================================================
# pull image and get image sha
# ===================================================

bash pull_image.sh

# login the registry
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${REGISTRY}

# get sha of image
export IMAGE_SHA=$(aws ecr describe-images \
 --registry-id 763104351884 \
 --repository-name ${REPO} \
 --image-ids imageTag=${TAG} \
 --query 'imageDetails[].imageDigest')


 # Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Successfully retrieved image SHA"
    echo "Image SHA: $IMAGE_SHA"
else
    echo "Failed to retrieve image SHA"
    exit 1
fi

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
# display json file on cloudwatch
# ===================================================



# ===================================================
# clean up
# ===================================================
