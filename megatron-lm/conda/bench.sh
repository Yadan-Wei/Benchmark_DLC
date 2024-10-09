#! /bin/bash
set -e
source args.sh

# dynamic environment settings
export PORT=$(comm -23 <(seq 50000 65536  | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
export CPU_COUNT=${SLURM_CPUS_PER_TASK}
export TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
export JOB_DIR="$(pwd)"

# basic environment settings
export MODEL_NAME="megatron"
export RUNTIME_DIR="/fsx/autobench/runtime"
export EXECUTION_NAME="train_${MODEL_NAME}_${INSTANCE_TYPE}_${FLAVOR}_${NUM_NODES}nodes_py${PYTHON_VERSION}_pt_${PYTORCH_VERSION}_cu${CUDA_VERSION}_${TIMESTAMP}"
export EXECUTION_PREFIX="${RUNTIME_PREFIX}${MODEL_NAME}_${INSTANCE_TYPE}_${FLAVOR}_py${PYTHON_VERSION}_pt_${PYTORCH_VERSION}_cu${CUDA_VERSION}"
export EXECUTION_DIR="${RUNTIME_DIR}/${EXECUTION_PREFIX}_${TIMESTAMP}"
export DATASET_DIR="${EXECUTION_DIR}/dataset"
export ENV_DIR="${EXECUTION_DIR}/env"
export DEPS_DIR="${EXECUTION_DIR}/deps"

# other environment settings
export OPEN_MPI_PATH=/opt/amazon/openmpi
export AMAZON_EFA_PATH=/opt/amazon/efa
export CUDA_HOME=/usr/local/cuda-$CUDA_VERSION
export PATH=$OPEN_MPI_PATH/bin:$CONDA_PREFIX/bin:$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$AMAZON_EFA_PATH/lib:$OPEN_MPI_PATH/lib:$CONDA_PREFIX/lib:$CUDA_HOME/lib64:$CUDA_HOME/lib:$LD_LIBRARY_PATH
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# ===================================================
# Prepare the Benchmarking Run
# ===================================================
# use a dependency map to store dependency_name -> commit_hash
declare -A DEPS_MAP
if [ ${SLURM_JOB_PARTITION} == 'queue1' ]; then
    DEPS_MAP['TransformerEngine']='bbafb02097e6ca1605c3c0cad84d59dbbcb6e94b'
elif [ ${SLURM_JOB_PARTITION} == 'queue2' ]; then
    DEPS_MAP['TransformerEngine']='8eae4ce2b8fdfbbe525fc8bfecb0df5498cc9687'
fi
DEPS_MAP['flash-attention']='d30f2e1cd50185c98ed88c0684b4a603f15bee37'
DEPS_MAP['apex']='6c8f384b40a596bbed960f5e8d9a808ebd0e93d8'
DEPS_MAP['Megatron-LM']='2c3468a49ed51324ae9b442e0d88416f1b29422b'
source find_reusable_runtime_environment.sh
if [ ${REUSE} -eq 1 ]; then
    echo "skipping recreating runtime, reusing ${EXECUTION_DIR} for ${EXECUTION_NAME}."
else
    echo "Cannot find reusable environment, creating..."
    mkdir -p ${EXECUTION_DIR}
    cd $JOB_DIR
    bash prep.sh 2>&1 | tee ${METRICS_DIR_PATH}/"prep_${TIMESTAMP}.log"
fi

# get hostnames
HOST_FILE="${METRICS_DIR_PATH}/hosts"
srun -N ${NUM_NODES} --partition=${SLURM_JOB_PARTITION} --nodelist ${SLURM_JOB_NODELIST} hostname > ${HOST_FILE}
cat $HOST_FILE

# ===================================================
# Benchmarking Run
# ===================================================
eval "$(/fsx/conda/bin/conda shell.bash hook)"
conda activate $ENV_DIR

# use TransformerEngine if on p5
if [ ${SLURM_JOB_PARTITION} == 'queue2' ]; then
    USE_TE_OPTIONS=1
else
    USE_TE_OPTIONS=0
fi

COMMON_OPTIONS=(
    "CUDA_DEVICE_MAX_CONNECTIONS=1"
    "NCCL_DEBUG=INFO"
    "NCCL_PROTO=LL,LL128,Simple"
    "FI_PROVIDER=efa"
    "FI_EFA_USE_DEVICE_RDMA=1"
    "RDMAV_FORK_SAFE=1"
    "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    "PATH=$PATH"
    "PORT=$PORT"
    "NNODES=$NUM_NODES"
    "HOSTFILE=$HOST_FILE"
)

CUSTOM_OPTIONS=(
    "GPT_HOME=${DATASET_DIR}/megatron"
    "DATASET=${DATASET_DIR}/megatron/my-gpt2_text_document/my-gpt2_text_document"
    "CHECKPOINT_PATH=${DATASET_DIR}/megatron/checkpoints/gpt2_345m"
    "VOCAB_FILE=${DATASET_DIR}/megatron/gpt2-vocab.json"
    "MERGES_FILE=${DATASET_DIR}/megatron/gpt2-merges.txt"
    "DATA_PATH=${DATASET_DIR}/megatron/my-gpt2_text_document/my-gpt2_text_document"
    "CUDA_DEVICE_MAX_CONNECTIONS=1"
    #https://github.com/NVIDIA/Megatron-LM/issues/330
    "NVTE_BIAS_GELU_NVFUSION=0"
    "USE_TE=${USE_TE_OPTIONS}"
)

for opt in ${CUSTOM_OPTIONS[@]} ${COMMON_OPTIONS[@]}; do
    MPI_OPTIONS+=" -x $opt"
    export $opt
done

LOG_FILE_NAME=${EXECUTION_NAME}.log
TRAIN_SCRIPT="bash train.sh"
echo "Check training logs at: ${JOB_DIR}"
cd $JOB_DIR
if [ ${NUM_NODES} == 1 ]; then
    echo "running single node"
    srun -N 1 --partition=${SLURM_JOB_PARTITION} --cpus-per-task=${CPU_COUNT} --nodelist ${SLURM_JOB_NODELIST} $TRAIN_SCRIPT 2>&1 | tee ${METRICS_DIR_PATH}/${LOG_FILE_NAME}
else
    echo "running using hosts:"
    $OPEN_MPI_PATH/bin/mpirun -n $NUM_NODES --hostfile $HOST_FILE -N 1 \
        --tag-output \
        --oversubscribe --allow-run-as-root \
        --mca btl_tcp_if_exclude lo,docker0 \
        $MPI_OPTIONS $TRAIN_SCRIPT 2>&1 | tee ${METRICS_DIR_PATH}/${LOG_FILE_NAME}
fi

# ===================================================
# Process Benchmarking Result
# ===================================================
python process_megatron_results.py \
    --log_file ${METRICS_DIR_PATH}/${LOG_FILE_NAME} \
    --metrics_dir_path ${METRICS_DIR_PATH} \
    --num_nodes ${NUM_NODES} \
    --flavor ${FLAVOR} \
    --python_version ${PYTHON_VERSION} \
    --pytorch_version ${PYTORCH_VERSION} \
    --cuda_version ${CUDA_VERSION}