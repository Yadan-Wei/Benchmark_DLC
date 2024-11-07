#!/bin/bash

set -exo pipefail


. config.sh


# Make sure the dir exists
mkdir -p $METRICS_DIR_PATH
mkdir -p $DATA_DIR
mkdir -p $IMAGE_DIR

# clean up old log
rm -rf $METRICS_DIR_PATH/*

# remove old image, disable in test to save time
# rm -rf $IMAGE_DIR/*

# Loop through each image source in the config

for IMAGE_TYPE in "${IMAGE_SOURCE[@]}"; do
    get_image_info "$IMAGE_TYPE"
    if [ $? -ne 0 ]; then
        echo "Error setting variables for $IMAGE_TYPE"
        continue
    fi
    export IMAGE="${REGISTRY}/${REPO}:${TAG}"
    export IMAGE_TYPE

    echo "Running training with:"
    echo "IMAGE: $IMAGE"

    # pull image
    bash pull_image.sh

    # for DLC get the image sha 
    if [ "${IMAGE_TYPE}" = "DLC" ];  then

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
        IMAGE_SHA="N/A"
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

# get all process training result job list as dependency of send to cloudwatch job
proess_result_job_ids=()
while read -r job_id; do
    proess_result_job_ids+=("$job_id")
done < ${METRICS_DIR_PATH}/process_res_job_list.txt

# Join job IDs into a comma-separated string
dep_string=$(IFS=','; echo "${proess_result_job_ids[*]}")

cd cloudwatch

# Submit an sbatch job with dependencies
sbatch --dependency=afterany:"${dep_string}" --kill-on-invalid-dep=yes --output ${METRICS_DIR_PATH}/send_to_cw_%j.out job_send_cw.sh

# ===================================================
# clean up
# ===================================================
