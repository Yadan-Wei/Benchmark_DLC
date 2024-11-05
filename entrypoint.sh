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

# Loop through each image source in the config

for image_type in "${IMAGE_SOURCE[@]}"; do
    get_image_info "$image_type"
    if [ $? -ne 0 ]; then
        echo "Error setting variables for $image_type"
        continue
    fi
    export IMAGE="${REGISTRY}/${REPO}:${TAG}"

    echo "Running training with:"
    echo "IMAGE: $IMAGE"

    # pull image
    bash pull_image.sh

    # for DLC get the image sha 
    if [ $image_type="DLC" ];  then
        # login the registry
        aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${REGISTRY}

        # get sha of image
        export IMAGE_SHA=$(aws ecr describe-images \
        --registry-id 763104351884 \
        --repository-name ${REPO} \
        --image-ids imageTag=${TAG} \
        --query 'imageDetails[].imageDigest' \
        --output text)


        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "Successfully retrieved image SHA"
            echo "Image SHA: $IMAGE_SHA"
        else
            echo "Failed to retrieve image SHA"
            exit 1
        fi
    else
        IMAGE_SHA=""
    fi

   
    # train model and generate json file
    for MODEL in "${MODELS[@]}"; do
        export MODEL
        cd $MODEL
        bash benchmark.sh 
        cd ..
    done

    # Reset the variables for the next iteration
    unset REGISTRY REPO TAG IMAGE
done


# ===================================================
# get the result job list and display json file on cloudwatch
# ===================================================

job_ids=()
while read -r job_id; do
    job_ids+=("$job_id")
done < ${METRICS_DIR_PATH}/job_list.txt

# Join job IDs into a comma-separated string
dep_string=$(IFS=','; echo "${job_ids[*]}")

cd cloudwatch

# Submit an sbatch job with dependencies
sbatch --parsable --dependency=afterany:"${dep_string}" --kill-on-invalid-dep=yes job_send_cw.sh

# ===================================================
# clean up
# ===================================================
