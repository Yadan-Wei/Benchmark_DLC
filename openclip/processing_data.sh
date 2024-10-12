#!/bin/bash

#SBATCH --job-name=openclip-data # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1
#SBATCH --cpus-per-task=192 # Number of CPU cores per task

# https://github.com/rom1504/img2dataset/blob/main/dataset_examples/cc12m.md
# https://github.com/rom1504/img2dataset/blob/main/dataset_examples/cc3m.md

# get to data directory
if [ ! -d "${MODEL_DATASET_DIR}" ]; then
    mkdir -p ${MODEL_DATASET_DIR}

    # download dataset
    wget https://storage.googleapis.com/conceptual_12m/cc12m.tsv

    # Add column names at the top of the file
    sed -i '1s/^/url\tcaption\n/' cc12m.tsv

    # download the images with img2dataset
    img2dataset --url_list cc12m.tsv --input_format "tsv"\
            --url_col "url" --caption_col "caption" --output_format webdataset\
            --output_folder cc12m --processes_count 128 --thread_count 128 --image_size 256\
                --enable_wandb False
fi
