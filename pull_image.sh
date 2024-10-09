#!/bin/bash

# update ECR credential 
source /fsx/autobench/credential

WORK_DIRECTORY=$(pwd)/images

cd $WORK_DIRECTORY

echo "Pull and squash ${IMAGE}."

# import and squash image
if [ ! -e "${TAG}.sqsh" ]; then
    enroot import -o "${TAG}.sqsh" "docker://${IMAGE}"
fi

echo "Pull and squash finished."

cd ..


# #!/bin/bash
# mkdir -p gpt2
# cd gpt2/

# wget https://huggingface.co/bigscience/misc-test-data/resolve/main/stas/oscar-1GB.jsonl.xz
# wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
# wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
# xz -d oscar-1GB.jsonl.xz