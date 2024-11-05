#!/bin/bash

#SBATCH --job-name=openclip-data # name of your job
#SBATCH --exclusive # job has exclusive use of the resource, no sharing
#SBATCH --wait-all-nodes=1
#SBATCH --ntasks=96
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1 # Number of CPU cores per task

set -ex

# this script is for first use if having no dataset available

# https://github.com/rom1504/img2dataset/blob/main/dataset_examples/cc12m.md
# https://github.com/rom1504/img2dataset/blob/main/dataset_examples/cc3m.md


# use 1 p4d 96 cpu cores each 4 threads to process data, average success rate is around 0.632, take 1.5hour, CPULoad 220.58


# to increase the success rate of downloading image, install below packages
# https://github.com/rom1504/img2dataset#setting-up-a-high-performance-dns-resolver
# install dns resolver

wget https://secure.nic.cz/files/knot-resolver/knot-resolver-release.deb
sudo dpkg -i knot-resolver-release.deb
sudo apt update
sudo apt install -y knot-resolver
sudo sh -c 'echo `hostname -I` `hostname` >> /etc/hosts'
sudo sh -c 'echo nameserver 127.0.0.1 > /etc/resolv.conf'
sudo systemctl stop systemd-resolved

sudo systemctl start kresd@1.service
sudo systemctl start kresd@2.service
sudo systemctl start kresd@3.service
sudo systemctl start kresd@4.service

apt-get update
apt-get install -y bind9


    # Configure BIND9
cat << EOF > /etc/bind/named.conf.options
options {
    recursive-clients 10000;
    resolver-query-timeout 30000;
    max-clients-per-query 10000;
    max-cache-size 2000m;
};
EOF

# Restart BIND9
systemctl restart bind9

# Update resolv.conf
echo "nameserver 127.0.0.1" | tee -a /etc/resolv.conf

# download dataset
wget https://storage.googleapis.com/conceptual_12m/cc12m.tsv

# Add column names at the top of the file
sed -i '1s/^/url\tcaption\n/' cc12m.tsv

# intsall img2datatset
pip install img2dataset

# download the images with img2dataset
# if use different instance adjust processes_count here based on instance cpu core number
img2dataset --url_list cc12m.tsv --input_format "tsv"\
        --url_col "url" --caption_col "caption" --output_format webdataset\
        --output_folder cc12m --processes_count 96 --thread_count 384 --image_size 256\
            --enable_wandb False

# stop services
sudo systemctl stop kresd@1.service
sudo systemctl stop kresd@2.service
sudo systemctl stop kresd@3.service
sudo systemctl stop kresd@4.service

# save data to s3 bucket
aws s3 cp cc12m s3://aws-conda-benchmark-datasets/cc12m --recursive
