import os
import json
import ast
from statistics import mean
NCCL_VERSION='NCCL version'
FI_PROVIDER='NET/OFI Initializing'
NET_WORK='Using network'

METRIC='elapsed time per iteration (ms):'
BATCH_SIZE='global batch size:'

NUM_NODES = 0
# FLAVOR = ""
# PYTHON_VERSION = ""
# PYTORCH_VERSION = ""
# CUDA_VERSION = ""
IMAGE=""
IMAGE_SHA=""
INSTANCE_TYPE=""
THROUGHPUT_TARGET = ""
ALLOWED_THROUGHPUT_VARIATION_PERCENTAGE = ""


def check_performance_or_fail_on_low_perf_number(
    actual_performance_number, targeted_performance_number, allowed_performance_variation_percentage
):
    allowed_variation = targeted_performance_number * allowed_performance_variation_percentage / 100
    lower_bound = targeted_performance_number - allowed_variation
    upper_bound = targeted_performance_number + allowed_variation
    if actual_performance_number > upper_bound:
        print(
            f"Actual performance {actual_performance_number} is greater than the upper bound {upper_bound}, very nice!"
        )
    if actual_performance_number < lower_bound:
        raise RuntimeError(
            f"Actual performance {actual_performance_number} is lower than the lower bound {lower_bound}, this is not good!"
        )
    print(
        f"performance is ok because actual_performance_number({actual_performance_number}) is within {allowed_performance_variation_percentage}% of targeted_performance_number({targeted_performance_number})"
    )


def parse_log(log_file, metrics_dir_path):
    nccl_version = ""
    network = ""
    ofi_version = ""
    iter_time = []
    batch_size = ""

    with open(log_file, 'r', errors='ignore') as f:
        lines = f.readlines();
        for line in lines:
            if not nccl_version:
                if NCCL_VERSION in line:
                    nccl_version = line[line.find(NCCL_VERSION)+len(NCCL_VERSION):].strip()

            if not network:
                if NET_WORK in line:
                    network = line[line.find(NET_WORK)+len(NET_WORK):].strip()

            if not ofi_version:
                if FI_PROVIDER in line:
                    ofi_version = line[line.find(FI_PROVIDER)+len(FI_PROVIDER):].strip()

            if not batch_size:
                if BATCH_SIZE in line:
                    start = line.find(BATCH_SIZE) + len(BATCH_SIZE)
                    end = line[start:].find("|")
                    batch_size = int(line[start:start+end].strip())

            if METRIC in line:
                    start = line.find(METRIC) + len(METRIC)
                    end = line[start:].find("|")
                    iter_time.append(line[start:start+end].strip())

    if not ofi_version:
        ofi_version = "N/A"

    iter_time = list(map(float, iter_time))
    iter_time.sort()
    average_iter_time = mean(iter_time[1:-1])
    # calculate throughput
    SEQUENCE_LENGTH = 2048
    MODEL_SIZE=22
    # calculate TFLOPS
    # https://blog.eleuther.ai/transformer-math/
    throughput = SEQUENCE_LENGTH * batch_size / average_iter_time * 1000    # tokens per second
    # calculate TFLOPS
    # https://blog.eleuther.ai/transformer-math/
    # 6 * num_params * tokens_per_second / num_gpus * 10^3  where 10^3 is the difference between billion and terra
    tflops = 6 * MODEL_SIZE * throughput / NUM_NODES / 8 / 1000 
    results = {
        "log_file": log_file,
        "num_nodes": NUM_NODES,
        "image":IMAGE,
        "image_sha": IMAGE_SHA,
        "instance_type": INSTANCE_TYPE,
        # "flavor": FLAVOR,
        # "python_version": PYTHON_VERSION,
        # "pytorch_version": PYTORCH_VERSION,
        # "cuda_version": CUDA_VERSION,
        "nccl_version": nccl_version,
        "network": network,
        "ofi_version": ofi_version,
        "model": {
            "name": "megatron",
            "perf_metrics": {
                "global_batch_size": batch_size,
                "iter_time": iter_time,
                "average_iter_time": average_iter_time,
                "throughput": throughput,
                "tflops": tflops,
                "measure": "tokens/s"
            }
        }
    }
    print(results)
    results = json.dumps(results)

    results_file_name = os.path.splitext(os.path.basename(log_file))[0] + '.metrics.json'
    results_file_path = os.path.join(metrics_dir_path, results_file_name)
    with open(results_file_path, 'w') as f:
        f.write(results)
    

    
    if THROUGHPUT_TARGET and ALLOWED_THROUGHPUT_VARIATION_PERCENTAGE:
        check_performance_or_fail_on_low_perf_number(throughput, THROUGHPUT_TARGET, ALLOWED_THROUGHPUT_VARIATION_PERCENTAGE)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='parse megatron benchmark results from log')
    parser.add_argument('--log_file', metavar='PATH', required=True, help='the path to log file')
    parser.add_argument('--metrics_dir_path', metavar='PATH', required=True, help='the path to the directory where json results should be written')
    parser.add_argument('--num_nodes', type=int, metavar='NUM', required=True, help='the number of nodes used to train')
    parser.add_argument('--image', type=str, required=True, help='the docker image use to train model')
    # parser.add_argument('--flavor', metavar='aws|oss|oss+efa', required=True, help='the flavor of pytorch used')
    # parser.add_argument('--python_version', metavar='VERSION', required=True, help='the python version used') 
    # parser.add_argument('--pytorch_version', metavar='VERSION', required=True, help='the pytorch version used')     
    # parser.add_argument('--cuda_version', metavar='VERSION', required=True, help='the cuda version used')  
    parser.add_argument('--target_throughput', required=False, help='target throughput number to check')  
    parser.add_argument('--allowed_throughput_variance_percentage', required=False, help='percentage of variation allowed for the thoughtput')
    parser.add_argument('--image_sha', type=str, required=True, help='the sha256 of image to identify image version')
    parser.add_argument("--instance_type", type-str, required=True, help='the instance type to do the training')  
    args = parser.parse_args()
    NUM_NODES = args.num_nodes
    IMAGE=args.image
    IMAGE = args.image
    IMAGE_SHA = args.image_sha
    # FLAVOR = args.flavor
    # PYTHON_VERSION = args.python_version
    # PYTORCH_VERSION = args.pytorch_version
    # CUDA_VERSION = args.cuda_version
    if args.target_throughput and args.allowed_throughput_variance_percentage:
        THROUGHPUT_TARGET = float(args.target_throughput)
        ALLOWED_THROUGHPUT_VARIATION_PERCENTAGE = float(args.allowed_throughput_variance_percentage)
    parse_log(args.log_file, args.metrics_dir_path)