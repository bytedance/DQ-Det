#!/usr/bin/env bash

cd $(dirname $0)
echo "====================================="
echo "Building up experimental environment"
echo "====================================="
sudo chmod 777 -R ../
sudo chmod 777 -R ./

# pip3 install git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI

echo "Start training"
echo "====================================="


python3 -m torch.distributed.launch --nproc_per_node=8 --use_env --master_port 47769  main.py --coco_path ../../../data/coco --batch_size 2 --lr_drop 40 --num_queries 300 --epochs 50 --dynamic_scale type3 --output_dir smca_single_scale

echo "Finish training"
echo "====================================="