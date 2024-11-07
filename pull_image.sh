#!/bin/bash

set -ex

# update ECR credential 
source /fsx/autobench/credential

WORK_DIRECTORY=$(pwd)/images

cd $WORK_DIRECTORY

echo "Pull and squash ${IMAGE}."

# import and squash image
if [ ! -e "${IMAGE_TYPE}_${TAG}.sqsh" ]; then
    enroot import -o "${IMAGE_TYPE}_${TAG}.sqsh" "docker://${IMAGE}"
fi

echo "Pull and squash finished."

cd ..

