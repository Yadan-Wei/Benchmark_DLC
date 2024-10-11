#!/bin/bash

#SBATCH --job-name=openclip # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1

set -ex;

###########################
###### User Variables #####
###########################

# # Parallelism decomposition variables
# : "${TENSOR_PARALLEL:=4}"
# : "${PIPELINE_PARALLEL:=2}"

# # Model parameters, defaults to 39B model
# # Refer to page 8 of this paper on how to tune models parameters
# # https://arxiv.org/pdf/2104.04473.pdf
# : "${NUM_LAYERS:=24}"
# : "${HIDDEN_SIZE:=1024}"
# : "${NUM_ATTENTION_HEADS:=16}"

# : "${SEQ_LENGTH:=2048}"
# : "${MAX_POSITION_EMBEDDINGS:=2048}"
# : "${MICRO_BATCH_SIZE:=1}"
# : "${GLOBAL_BATCH_SIZE:= $((8*$NUM_NODES))}"

# # default variables for Enroot
: "${DATA_PATH:=/fsx}"
: "${FSX_MOUNT:=${MODEL_DATASET_DIR}:$DATA_PATH}"

###########################
## Environment Variables ##
###########################

# https://discuss.pytorch.org/t/nccl-network-is-unreachable-connection-refused-when-initializing-ddp/137352
# https://github.com/pytorch/pytorch/issues/68893
# need use ifconfig to check host node interface and change here accordingly
export NCCL_SOCKET_IFNAME=enp
export NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_DEBUG=INFO
export LOGLEVEL=INFO
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
     git clone https://github.com/mlfoundations/open_clip.git
     pip install -U pip
     pip install 'open_clip_torch[training]'
     export wds_WDS_DATA_PATH=${DATA_PATH}
     "


declare -a TORCHRUN_ARGS=(
    # change this to match the number of gpus per node:
    --nproc_per_node=8
    --nnodes=$SLURM_JOB_NUM_NODES
    --rdzv_id=$SLURM_JOB_ID
    --rdzv_backend=c10d
    --rdzv_endpoint=$(hostname)
)

# declare -a MEGATRON_ARGS=(
#         --num-layers $NUM_LAYERS
#         --hidden-size $HIDDEN_SIZE
#         --num-attention-heads $NUM_ATTENTION_HEADS
#         --seq-length $SEQ_LENGTH
#         --max-position-embeddings $MAX_POSITION_EMBEDDINGS
#         --micro-batch-size $MICRO_BATCH_SIZE
#         --global-batch-size $GLOBAL_BATCH_SIZE
# )

# declare -a MEGATRON_PARALLELISM=(
#         --tensor-model-parallel-size $TENSOR_PARALLEL
#         --pipeline-model-parallel-size $PIPELINE_PARALLEL
# )

# 
# 2 * 8 * 256 * 1000

srun -l "${ARGS[@]}" torchrun "${TORCHRUN_ARGS[@]}" /workplace/open_clip/src/open_clip_train/main.py \
    --train-data "${DATA_PATH}/cc3m/{00000..00331}.tar" \
    --train-num-samples 10968539 \
    --save-frequency 1 \
    --dataset-type webdataset \
    --batch-size 320 \
    --precision amp \
    --workers 4 \
    --log-every-n-steps 10 \
    --epochs=100 
    # --imagenet-val /data/imagenet/validation/

# srun --cpu_bind=v --accel-bind=gn python -u src/open_clip_train/main.py \
#     --save-frequency 1 \
#     --report-to tensorboard \
#     --train-data="/data/LAION-400M/{00000..41455}.tar" \
#     --warmup 2000 \
#     --batch-size=256 \
#     --epochs=32 \
#     --workers=8 \
#     --model ViT-B-32 \
#     --name "ViT-B-32-Vanilla" \
#     --seed 0 \
#     --local-loss \
#     --gather-with-grad





# srun ${AUTO_RESUME} -l "${ARGS[@]}" python -m torch.distributed.run "${TORCHRUN_ARGS[@]}" /workspace/Megatron-LM/pretrain_gpt.py \
#         "${MEGATRON_PARALLELISM[@]}" \
#         "${MEGATRON_ARGS[@]}" \
#         --train-iters 1200 \
#         --distributed-backend nccl \
#         --lr-decay-iters 320000 \
#         --lr-warmup-fraction .01 \
#         --lr 0.00015 \
#         --min-lr 1.0e-5 \
#         --lr-decay-style cosine \
#         --log-interval 100 \
#         --eval-iters 10 \
#         --eval-interval 1000 \
#         --save-interval 10000 \
#         --data-path "${DATA_PATH}/my-gpt2_text_document/my-gpt2_text_document" \
#         --vocab-file "${DATA_PATH}/gpt2-vocab.json" \
#         --merge-file "${DATA_PATH}/gpt2-merges.txt" \
#         --split 949,50,1 \
#         --clip-grad 1.0 \
#         --weight-decay 1e-2 \
#         --adam-beta1 0.9 \
#         --adam-beta2 0.95 \
#         --init-method-std 0.006 \
#         --bf16 \
#         --recompute-activations 



#SBATCH --nodes=32
#SBATCH --gres=gpu:4
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=6


# eval "$(/path/to/conda/bin/conda shell.bash hook)" # init conda
# conda activate open_clip
# export CUDA_VISIBLE_DEVICES=0,1,2,3
# export MASTER_PORT=12802

# master_addr=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
# export MASTER_ADDR=$master_addr

# cd /shared/open_clip
# export PYTHONPATH="$PYTHONPATH:$PWD/src"
# srun --cpu_bind=v --accel-bind=gn python -u src/open_clip_train/main.py \
#     --save-frequency 1 \
#     --report-to tensorboard \
#     --train-data="/data/LAION-400M/{00000..41455}.tar" \
#     --warmup 2000 \
#     --batch-size=256 \
#     --epochs=32 \
#     --workers=8 \
#     --model ViT-B-32 \
#     --name "ViT-B-32-Vanilla" \
#     --seed 0 \
#     --local-loss \
#     --gather-with-grad


# cd open_clip/src
# torchrun --nproc_per_node=4 \
#     --rdzv_endpoint=$HOSTE_NODE_ADDR \
#     -m open_clip_train.main \
#     --train-data '/data/cc12m/cc12m-train-{0000..2175}.tar' \
#     --train-num-samples 10968539 \
#     --dataset-type webdataset \
#     --batch-size 320 \
#     --precision amp \
#     --workers 4 \
#     --imagenet-val /data/imagenet/validation/