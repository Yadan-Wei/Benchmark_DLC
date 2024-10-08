
#!/bin/bash

set -ex;

#####################
# Install megatron-lm 
#####################

if [ ! -d "$(pwd)/workspace/Megatron-LM" ]; then
    mkdir workspace
    cd workspace 
    git clone --depth 1 --branch core_v0.4.0 https://github.com/NVIDIA/Megatron-LM.git
    cd Megatron-LM 
    python3 -m pip install nltk  
    python -m pip install .
fi



