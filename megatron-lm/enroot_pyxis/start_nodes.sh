NNODES=$1
START=$2
END=$(($START + $NNODES - 1))
while true;
do
  echo "Launching $NNODES nodes from queue1-dy-p4d24xlarge-[$START-$END]"
  srun -N $NNODES --nodelist queue1-dy-p4d24xlarge-[$START-$END]  pwd;
  sleep 400;
done