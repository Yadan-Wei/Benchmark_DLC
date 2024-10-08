#! /bin/bash

set -e

# ===================================================
# Get Dataset
# ===================================================
if [ ! -d "${DATASET_DIR}" ]; then
    mkdir -p ${DATASET_DIR}
    aws s3 sync s3://aws-conda-benchmark-datasets/megatron ${DATASET_DIR}/megatron
fi

# ===================================================
# Setup Conda Environment
# ===================================================
# if [ ${FLAVOR} == 'aws' ]; then
#     export CHANNEL_ARGS="-c ${CONDA_CHANNEL} -c pytorch -c nvidia -c conda-forge"
# else
#     export CHANNEL_ARGS="-c pytorch -c nvidia"
# fi

# if [ ! -d "${ENV_DIR}" ]; then
#     echo "creating conda env at path: ${ENV_DIR}"
#     PKGS="python=${PYTHON_VERSION} pytorch=${PYTORCH_VERSION} pytorch-cuda=${CUDA_VERSION} torchvision torchaudio"
#     /fsx/conda/bin/mamba create -y -p ${ENV_DIR} ${PKGS} ${CHANNEL_ARGS}
#     if [ ${FLAVOR} == 'oss+efa' ]; then
#         /fsx/conda/bin/conda install -y -p ${ENV_DIR} aws-ofi-nccl -c ${CONDA_CHANNEL} -c conda-forge
#     fi
# else
#     echo "Env at path ${ENV_DIR} already exist, skip creating"
# fi

# # ===================================================
# # Setup p4/p5 specific dependencies
# # ===================================================
# if [ ${SLURM_JOB_PARTITION} == 'queue1' ]; then
#     TE_HASH='bbafb02097e6ca1605c3c0cad84d59dbbcb6e94b'
# elif [ ${SLURM_JOB_PARTITION} == 'queue2' ]; then
#     TE_HASH='8eae4ce2b8fdfbbe525fc8bfecb0df5498cc9687'
# fi
# FLASH_ATTN_BRANCH='v2.0.4'
# APEX_HASH='6c8f384b40a596bbed960f5e8d9a808ebd0e93d8'
# MEGATRON_LM_HASH='2c3468a49ed51324ae9b442e0d88416f1b29422b'

# # ===================================================
# # Install Other Dependencies
# # ===================================================
# eval "$(/fsx/conda/bin/conda shell.bash hook)"
# conda activate $ENV_DIR
# mkdir -p $DEPS_DIR

# # install megatron python dependencies
# mamba install -y regex astunparse ninja pyyaml mkl mkl-include setuptools cmake cffi typing_extensions future six requests libcurl dataclasses packaging
# pip install six regex tensorboardX daal4py deepspeed pyarrow pybind11

# # install flash attention
# cd $DEPS_DIR
# if [ ! -d "$DEPS_DIR/flash-attention" ]; then
#   git clone -b ${FLASH_ATTN_BRANCH} https://github.com/Dao-AILab/flash-attention.git
#   cd flash-attention
#   python setup.py install
# fi

# # install transformer engine
# cd $DEPS_DIR
# if [ ! -d "$DEPS_DIR/TransformerEngine" ]; then
#   git clone --branch stable --recursive https://github.com/NVIDIA/TransformerEngine.git
#   cd TransformerEngine
#   git checkout ${TE_HASH}
#   git submodule update --init --recursive
#   export NVTE_FRAMEWORK="pytorch"
#   export CUDNN_PATH=${CUDA_HOME}
#   export CUDNN_INCLUDE_DIR="${CUDA_HOME}/include"
#   pip install .
# fi

# # install apex
# cd $DEPS_DIR
# if [ ! -d "$DEPS_DIR/apex" ]; then
#   git clone https://github.com/NVIDIA/apex.git
#   cd apex
#   git checkout ${APEX_HASH}
#   pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation \
#     --config-settings "--global-option=--cpp_ext" \
#     --config-settings "--global-option=--cuda_ext" \
#     ./
# fi

# clone Megatron, only need scripts
cd $DEPS_DIR
if [ ! -d "$DEPS_DIR/Megatron-LM" ]; then
  git clone https://github.com/NVIDIA/Megatron-LM.git
  cd Megatron-LM
  git checkout ${MEGATRON_LM_HASH}
  cd $DEPS_DIR
fi

# # fix error -> AttributeError: module 'numpy' has no attribute 'float'
# pip install numpy==1.23.5

# mount Megatron, your dataset, and checkpoints
docker pull nvcr.io/nvidia/pytorch:xx.xx-py3
docker run --gpus all -it --rm -v /path/to/megatron:/workspace/megatron \
                                -v /path/to/dataset:/workspace/dataset \
                                -v /path/to/checkpoints:/workspace/checkpoints \
                                nvcr.io/nvidia/pytorch:xx.xx-py3

#!/bin/bash

# Clone the Megatron-LM repository
git clone --depth 1 --branch core_v0.4.0 https://github.com/NVIDIA/Megatron-LM.git

# Navigate to the cloned repository
cd Megatron-LM

# Install NLTK
python3 -m pip install nltk

# Install Megatron-LM
python -m pip install .