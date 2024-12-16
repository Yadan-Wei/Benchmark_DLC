set -ex;

cd src

export CUDA_VERSION=12.4
export CUDA_HOME=/usr/local/cuda-$CUDA_VERSION
export PATH=$CONDA_PREFIX/bin:$CUDA_HOME/bin:$PATH

export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$CUDA_HOME/lib64:$CUDA_HOME/lib:$LD_LIBRARY_PATH
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_DEVICE_MAX_CONNECTIONS=1

torchrun --nproc_per_node=2 -m open_clip_train.main  \
        --train-data "/home/ubuntu/open_clip/cc3m/{00000..00331}.tar"  \
        --save-frequency 1 \
    --train-num-samples 12423374 \
    --dataset-type webdataset \
    --batch-size 64 \
    --warmup 2000 \
    --model ViT-B-32 \
    --precision amp \
    --wd 0.2 \
    --workers 4 \
    --dataset-resampled \
    --log-every-n-steps 10 \
    --epochs=1 2>&1
