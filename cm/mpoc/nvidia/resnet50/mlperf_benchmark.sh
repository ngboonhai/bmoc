#! /bin/bash -ex

git clone https://github.com/mlcommons/inference_results_v1.0.git ~/
echo "export INFERENCE_NVIDIA_PATH=~/inference_results_v1.0/closed/NVIDIA" >> ~/.bashrc
echo "export MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build" >> ~/.bashrc
mkdir -p $MLPERF_SCRATCH_PATH
source ~/.bashrc

## Dependencies only for Jetson system
bash $MLPERF_SCRATCH_PATH/script/install_xavier_dependencies.sh

## Build TensorRT and MLPerf Plugins
make build 

## Download dataset from Image-net Org.
mkdir -p $MLPERF_SCRATCH_PATH/data/imagenet
wget https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar -o /tmp/ILSVRC2012_img_val.tar
tar xf /tmp/ILSVRC2012_img_val.tar -C $MLPERF_SCRATCH_PATH/data/imagenet


## Perform dataset validation after downloaded.
bash code/resnet50/tensorrt/download_data.sh


## Download Onnx Model from Zenodo Org.
bash $INFERENCE_NVIDIA_PATH/code/resnet50/tensorrt/download_model.sh


## Execute MLPerf Benchmark
# make run RUN_ARGS="--benchmarks=resnet50 --scenarios=SingleStream --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=resnet50 --scenarios=SingleStream --test_mode=AccuracyOnly"
# make run RUN_ARGS="--benchmarks=resnet50 --scenarios=MultiStream --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=resnet50 --scenarios=MultiStream --test_mode=AccuracyOnly"
# make run RUN_ARGS="--benchmarks=resnet50 --scenarios=Offline --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=resnet50 --scenarios=Offline --test_mode=AccuracyOnly"
