#!/bin/bash

#SBATCH --job-name=openclip-train # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1

set -ex;

###########################
###### User Variables #####
###########################

# default variables for Enroot
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

export NCCL_DEBUG=INFO
# export LOGLEVEL=INFO
export CUDA_LAUNCH_BLOCKING=0
export FI_EFA_SET_CUDA_SYNC_MEMOPS=0
export NCCL_BUFFSIZE=8388608
export NCCL_P2P_NET_CHUNKSIZE=524288

# async runtime error ...
export CUDA_DEVICE_MAX_CONNECTIONS=1

#########################
## Command and Options ##
#########################

declare -a ARGS=(
    --container-image ${IMAGE_DIR}/${TAG}.sqsh
    --container-mounts $FSX_MOUNT
    --container-name openclip-training
)

#####################
# Install open clip training dependency 
#####################
srun -l "${ARGS[@]}" \
     bash -c "
     mkdir /workplace
     cd /workplace
     rm -rf open_clip
     git clone https://github.com/Yadan-Wei/open_clip.git
     pip install -U pip
     cd open_clip
     pip install -r requirements-training.txt
     "

# add training directory to find modules
ARGS+=(--container-workdir /workplace/open_clip/src/)

declare -a TORCHRUN_ARGS=(
    # change this to match the number of gpus per node:
    --nproc_per_node=8
    --nnodes=$SLURM_JOB_NUM_NODES
    --rdzv_id=$SLURM_JOB_ID
    --rdzv_backend=c10d
    --rdzv_endpoint=$(hostname)
)


srun -l "${ARGS[@]}" torchrun -m "${TORCHRUN_ARGS[@]}" open_clip_train.main \
    --train-data "${DATA_PATH}/${DATA_SOURCE}/{00000..01242}.tar" \
    --save-frequency 1 \
    --train-num-samples 12423374 \
    --dataset-type webdataset \
    --batch-size 320 \
    --warmup 2000 \
    --model ViT-B-32 \
    --precision amp \
    --wd 0.2 \
    --workers 4 \
    --dataset-resampled \
    --log-every-n-steps 10 \
    --epochs=1 2>&1


    