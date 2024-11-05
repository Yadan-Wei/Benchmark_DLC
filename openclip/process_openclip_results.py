import os
import json
import ast
import re
import math
from statistics import mean
NCCL_VERSION='NCCL version'
FI_PROVIDER='NET/OFI Initializing'
NET_WORK='Using network'
METRIC='Train Epoch: '
BATCH_SIZE='batch size per GPU ='
TOKENS='tokens_per_sample='
SKIP=5

NUM_NODES = 0
IMAGE= ""
IMAGE_SHA = ""
INSTANCE_TYPE = ""


def parse_log(log_file_path, metrics_dir_path):
    sample_per_sec_per_gpu = {}
    with open(log_file_path, 'r') as f:
        lines = f.readlines();
        for line in lines:
            if METRIC in line:

                # Regex to extract Train Epoch number
                epoch_match = re.search(r'Train Epoch: (\d+)', line)
                train_epoch = int(epoch_match.group(1)) if epoch_match else None
                
                # Regex to extract 30.1366/s/gpu metric
                gpu_metric_match = re.search(r'(\d+\.\d+)/s/gpu', line)
                gpu_metric = float(gpu_metric_match.group(1)) if gpu_metric_match else None

                if train_epoch not in sample_per_sec_per_gpu:
                    sample_per_sec_per_gpu[train_epoch] = [gpu_metric]
                else:
                    sample_per_sec_per_gpu[train_epoch].append(gpu_metric)

    for k, v in sample_per_sec_per_gpu.items():
        sample_per_sec_per_gpu[k] = mean(v[1:])

    results = {
        "image": IMAGE,
        "num_nodes": NUM_NODES,
        "image_sha": IMAGE_SHA,
        "instance_type": INSTANCE_TYPE,
        "model": {
            "name": "openclip",
            "perf_metrics": {
               "average_sample_per_sec_per_gpu": mean(list(sample_per_sec_per_gpu.values())),
               "throughput": mean(list(sample_per_sec_per_gpu.values()))*NUM_NODES*8,
               "measure": "text and image pairs/s"
            }
        }
    }
    results = json.dumps(results)

    results_file_name = os.path.basename(os.path.normpath(log_file_path)) + '.metrics.json'
    results_file_path = os.path.join(metrics_dir_path, results_file_name)
    with open(results_file_path, 'w') as f:
        f.write(results)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='parse openclip benchmark results from log')
    parser.add_argument('--log_file_path', metavar='PATH', required=True)
    parser.add_argument('--metrics_dir_path', metavar='PATH', required=True)
    parser.add_argument('--num_nodes', type=int, metavar='NUM', required=True, help='the number of nodes used to train')
    parser.add_argument('--image', type=str, required=True, help='the docker image use to train model')
    parser.add_argument('--image_sha', type=str, required=True, help='the sha256 of image to identify image version')
    parser.add_argument("--instance_type", type-str, required=True, help='the instance type to do the training')
    args = parser.parse_args()
    NUM_NODES = args.num_nodes
    IMAGE = args.image
    IMAGE_SHA = args.image_sha
    INSTANCE_TYPE=args.instance_type
    parse_log(args.log_file_path, args.metrics_dir_path)