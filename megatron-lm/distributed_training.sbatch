#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


#SBATCH --job-name=megatron_gpt # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1


set -ex;

###########################
###### User Variables #####
###########################

# Parallelism decomposition variables
: "${TENSOR_PARALLEL:=4}"
: "${PIPELINE_PARALLEL:=2}"

# Model parameters, defaults to 39B model
# Refer to page 8 of this paper on how to tune models parameters
# https://arxiv.org/pdf/2104.04473.pdf
: "${NUM_LAYERS:=24}"
: "${HIDDEN_SIZE:=1024}"
: "${NUM_ATTENTION_HEADS:=16}"

: "${SEQ_LENGTH:=2048}"
: "${MAX_POSITION_EMBEDDINGS:=2048}"
: "${MICRO_BATCH_SIZE:=1}"
: "${GLOBAL_BATCH_SIZE:= $((8*$NUM_NODES))}"

# # default variables for Enroot
# : "${IMAGE:=$(pwd)/megatron-training-dlc.sqsh}"
: "${DATA_PATH:=/fsx}"
: "${FSX_MOUNT:=${MODEL_DATASET_DIR}:$DATA_PATH}"

###########################
## Environment Variables ##
###########################

# https://discuss.pytorch.org/t/nccl-network-is-unreachable-connection-refused-when-initializing-ddp/137352
# https://github.com/pytorch/pytorch/issues/68893
# need use ifconfig to check host node interface and change here accordingly
# p4d: ens  p548:enp
if [ "${INSTANCE_TYPE}" = "p4d" ]; then
    export NCCL_SOCKET_IFNAME=ens
elif [ "${INSTANCE_TYPE}" = "p5" ]; then
    export NCCL_SOCKET_IFNAME=enp
fi

export NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_DEBUG=INFO

# async runtime error ...
export CUDA_DEVICE_MAX_CONNECTIONS=1

#########################
## Command and Options ##
#########################

declare -a ARGS=(
    --container-image ${IMAGE_DIR}/${TAG}.sqsh
    --container-mounts $FSX_MOUNT
    --container-name megatron-training-${TAG}
)

#####################
# Install megatron-lm 
#####################
srun -l "${ARGS[@]}" \
     bash -c "
     mkdir /workspace
     cd /workspace
         git clone --depth 1 --branch core_v0.4.0 https://github.com/NVIDIA/Megatron-LM.git
         cd Megatron-LM
         python3 -m pip install nltk
         python -m pip install .
     "

declare -a TORCHRUN_ARGS=(
    # change this to match the number of gpus per node:
    --nproc_per_node=8
    --nnodes=$SLURM_JOB_NUM_NODES
    --rdzv_id=$SLURM_JOB_ID
    --rdzv_backend=c10d
    --rdzv_endpoint=$(hostname)
)

declare -a MEGATRON_ARGS=(
        --num-layers $NUM_LAYERS
        --hidden-size $HIDDEN_SIZE
        --num-attention-heads $NUM_ATTENTION_HEADS
        --seq-length $SEQ_LENGTH
        --max-position-embeddings $MAX_POSITION_EMBEDDINGS
        --micro-batch-size $MICRO_BATCH_SIZE
        --global-batch-size $GLOBAL_BATCH_SIZE
)

declare -a MEGATRON_PARALLELISM=(
        --tensor-model-parallel-size $TENSOR_PARALLEL
        --pipeline-model-parallel-size $PIPELINE_PARALLEL
)

AUTO_RESUME=""
if [ -d "/opt/sagemaker_cluster" ]; then
    echo "Detected Hyperpod cluster.. enabling --auto-resume=1"
    AUTO_RESUME="--auto-resume=1"
fi

srun ${AUTO_RESUME} -l "${ARGS[@]}" python -m torch.distributed.run "${TORCHRUN_ARGS[@]}" /workspace/Megatron-LM/pretrain_gpt.py \
        "${MEGATRON_PARALLELISM[@]}" \
        "${MEGATRON_ARGS[@]}" \
        --train-iters 1200 \
        --distributed-backend nccl \
        --lr-decay-iters 320000 \
        --lr-warmup-fraction .01 \
        --lr 0.00015 \
        --min-lr 1.0e-5 \
        --lr-decay-style cosine \
        --log-interval 100 \
        --eval-iters 10 \
        --eval-interval 1000 \
        --save-interval 10000 \
        --data-path "${DATA_PATH}/my-gpt2_text_document/my-gpt2_text_document" \
        --vocab-file "${DATA_PATH}/gpt2-vocab.json" \
        --merge-file "${DATA_PATH}/gpt2-merges.txt" \
        --split 949,50,1 \
        --clip-grad 1.0 \
        --weight-decay 1e-2 \
        --adam-beta1 0.9 \
        --adam-beta2 0.95 \
        --init-method-std 0.006 \
        --bf16 \
        --recompute-activations 2>&1
