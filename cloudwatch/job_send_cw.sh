#!/bin/bash
set -e

CURRENT_DATE_TIME=$1

# send log to cloudwatch
if [[ $SEND_TO_CLOUDWATCH == "true" || $SEND_TO_CLOUDWATCH == "True" ]]; then
      python send_to_cw_experiment.py --metrics_dir_path $LOGS_DIR --job_name "Benchmark_${CURRENT_DATE_TIME}" 
fi