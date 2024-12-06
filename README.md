# Benchmark_DLC

## Background
To ensure that Deep Learning Containers (DLCs) images maintain proper functionality and avoid performance degradation compared to other containers, we incorporate benchmarking as part of the testing process. The benchmarks are designed to measure the throughput of various models running within the DLC images. The throughput of each model is measured and compared against established baselines or reference points, which may include other container implementations.
## Infrastructure
![DLC Image Benchmark](https://github.com/user-attachments/assets/a644f226-a921-48fc-879f-748743bfebc5)


## Prerequisites 

Parallel Cluster with Enroot and Pyxis Installed.

Have NGC token and AWS account credentials.

## Get Started

1. Follow this instruction[https://github.com/NVIDIA/enroot/blob/master/doc/cmd/import.md] to Configure credentials for container registry
2. Use config.sh to set instance type, nodes number,  model and images you want to use.
3. Use bash ./entrypoint.sh to submit the job. (We use sbatch to submit the job, it will execute when resources are available)
4. Check the results from cloudwatch dashboard. (Below is a sample output) 



configure ECR for enroot import if using new cluster
config can be find in /etc/enroot/enroot.conf
ENROOT_CONFIG_PATH         /home/$(id -u -n)/.config/enroot
https://github.com/NVIDIA/enroot/blob/master/doc/cmd/import.md
