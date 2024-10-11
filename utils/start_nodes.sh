NNODES=$1
START=$2
QUEUE=${3:-queue1}
END=$(($START + $NNODES - 1))
while true; do
  case "$QUEUE" in
        queue1)
            echo "Launching $NNODES nodes from queue1-dy-p4d24xlarge-[$START-$END]"
            srun -N $NNODES --partition="queue1" --nodelist queue1-dy-p4d24xlarge-[$START-$END] pwd
            ;;
        queue2)
            echo "Launching $NNODES nodes from queue2-dy-p548xlarge-[$START-$END]"
            srun -N $NNODES --partition="queue2" --nodelist queue2-dy-p548xlarge-[$START-$END] pwd
            ;;
        queue3)
            echo "Launching $NNODES nodes from queue3-dy-p548xlarge-[$START-$END]"
            srun -N $NNODES --partition="queue3" --nodelist queue3-dy-m524xlarge-[$START-$END] pwd
            ;;
        *)
            echo "Invalid queue name. Using the default queue1."
            srun -N $NNODES --partition="queue1" --nodelist queue1-dy-p4d24xlarge-[$START-$END] pwd
            ;;
  esac
  sleep 400
done