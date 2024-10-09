#! /bin/bash
#
# GPT2 345M model config https://arxiv.org/pdf/1909.08053.pdf
# GPT3 22B model config https://arxiv.org/pdf/2205.05198.pdf

# remove previous checkpoints
rm -rf ${DATASET_DIR}/megatron/checkpoints/
echo "using python from following environment:"
which python

# initialize defaults for multinode
if [ ${NNODES} -gt 1 ]; then
    MULTINODE_PARAMS+=" --node_rank=${OMPI_COMM_WORLD_RANK}"
    MULTINODE_PARAMS+=" --master_addr=$(head -n 1 ${HOSTFILE})"
    MULTINODE_PARAMS+=" --master_port=${PORT}"
fi

# initialize TransformerEngine parameters
if [ ${USE_TE} -eq 1 ]; then
    TRANSFORMER_IMPL="transformer_engine"
    ADDITIONAL_PARAMS+=" --attention-softmax-in-fp32"
else
    TRANSFORMER_IMPL="local"
fi

torchrun --nproc-per-node 8 --nnodes ${NNODES} \
  ${MULTINODE_PARAMS:+$MULTINODE_PARAMS} \
  ${DEPS_DIR}/Megatron-LM/pretrain_gpt.py \
  --tensor-model-parallel-size 1 \
  --pipeline-model-parallel-size 1 \
  --sequence-parallel \
  --num-layers 24 \
  --hidden-size 1024 \
  --num-attention-heads 16 \
  --micro-batch-size 1 \
  --global-batch-size $((8*$NNODES)) \
  --seq-length 2048 \
  --max-position-embeddings 2048 \
  --train-iters 1200 \
  --lr-decay-iters 320000 \
  --save ${CHECKPOINT_PATH} \
  --load ${CHECKPOINT_PATH} \
  --data-path ${DATA_PATH} \
  --vocab-file ${VOCAB_FILE} \
  --merge-file ${MERGES_FILE} \
  --split 949,50,1 \
  --distributed-backend nccl \
  --lr 0.00015 \
  --lr-decay-style cosine \
  --min-lr 1.0e-5 \
  --weight-decay 1e-2 \
  --clip-grad 1.0 \
  --lr-warmup-fraction .01 \
  --log-interval 100 \
  --save-interval 10000 \
  --eval-interval 1000 \
  --eval-iters 10 \
  --adam-beta1 0.9 \
  --adam-beta2 0.95 \
  --init-method-std 0.006 \
  --bf16 \
  --transformer-impl ${TRANSFORMER_IMPL} \
  ${ADDITIONAL_PARAMS:+$ADDITIONAL_PARAMS}