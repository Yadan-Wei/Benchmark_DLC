#!/bin/bash

# update ECR credential 
source /fsx/autobench/credential

IMAGES=(
    763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-training:2.4.0-gpu-py311-cu124-ubuntu22.04-ec2
    )

# import and squash image
for IMAGE in "${IMAGES[@]}"; do
    enroot import "$IMAGE"
done





#!/bin/bash
mkdir -p gpt2
cd gpt2/

wget https://huggingface.co/bigscience/misc-test-data/resolve/main/stas/oscar-1GB.jsonl.xz
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
xz -d oscar-1GB.jsonl.xz