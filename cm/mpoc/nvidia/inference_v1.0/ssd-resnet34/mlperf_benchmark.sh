#set -eo pipefail
set -x

## Variable declaration
MLPERF_INFERENCE_REPO="inference_results_v1.0"
INFERENCE_NVIDIA_PATH=~/inference_results_v1.0/closed/NVIDIA
MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build

## Checkout MLPerf Inference v1.0 repo from GitHub
[ ! -d "$MLPERF_INFERENCE_REPO" ] && git clone https://github.com/mlcommons/$MLPERF_INFERENCE_REPO.git ~/$MLPERF_INFERENCE_REPO

## Create NVIDIA MLPerf scratch path
[ ! -d "$MLPERF_SCRATCH_PATH" ] && mkdir -p $MLPERF_SCRATCH_PATH

## Configure MLPerf scratch path into session environment
grep -Rn "$MLPERF_SCRATCH_PATH" ~/.bashrc
[ "$?" -ne "0" ] && echo "export INFERENCE_NVIDIA_PATH=$INFERENCE_NVIDIA_PATH" >> ~/.bashrc && echo "export MLPERF_SCRATCH_PATH=$MLPERF_SCRATCH_PATH" >> ~/.bashrc
source ~/.bashrc

## Check and Set NVIDIA Mlperf scratch path as envrionment variable
[[ ! -z `export | grep INFERENCE_NVIDIA_PATH` ]] && echo $INFERENCE_NVIDIA_PATH || export INFERENCE_NVIDIA_PATH=~/inference_results_v1.0/closed/NVIDIA
[[ ! -z `export | grep MLPERF_SCRATCH_PATH` ]] && echo $MLPERF_SCRATCH_PATH || export MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build
export | grep $INFERENCE_NVIDIA_PATH

## Update some files which errors detect from Origical files from Repo
cat bmoc/cm/mpoc/nvidia/inference_v1.0/install_xavier_dependencies.sh > $INFERENCE_NVIDIA_PATH/scripts/install_xavier_dependencies.sh
cat bmoc/cm/mpoc/nvidia/inference_v1.0/Makefile > $INFERENCE_NVIDIA_PATH/Makefile
cat bmoc/cm/mpoc/nvidia/inference_v1.0/lwis_buffers.h > $INFERENCE_NVIDIA_PATH/code/harness/lwis/include/lwis_buffers.h

## Dependencies only for Jetson system
sudo apt-get update
sudo apt-get install -y python-dev python3-dev python-pip python3-pip curl libopenmpi2
pip install absl-py
pip3 install scikit-build astunparse
bash $INFERENCE_NVIDIA_PATH/scripts/install_xavier_dependencies.sh

# Re-check and install ONNX preprocessing again.
pip install numpy
pip3 install onnx
cd /tmp \
&& git clone https://github.com/NVIDIA/TensorRT.git \
&& cd TensorRT \
&& git checkout release/7.1 \
&& cd tools/onnx-graphsurgeon \
&& make build \
&& sudo python3 -m pip install --no-deps -t /usr/local/lib/python3.6/dist-packages --force-reinstall dist/*.whl \
&& cd /tmp \
&& rm -rf TensorRT

## Build TensorRT and MLPerf Plugins
cd $INFERENCE_NVIDIA_PATH
[ ! -d "$MLPERF_SCRATCH_PATH/inference" ] && make clone_loadgen
make build_plugins
make build_loadgen
make build_harness

# Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_data.sh
if [ -f $MLPERF_SCRATCH_PATH/data/coco/*.zip ]; then
    rm $MLPERF_SCRATCH_PATH/data/coco/*.zip
fi

## Download Onnx Model from Zenodo Org.
if [ ! -f $MLPERF_SCRATCH_PATH/models/SSDResNet34/resnet34-ssd1200.pytorch ]; then
    cd $INFERENCE_NVIDIA_PATH
    bash $INFERENCE_NVIDIA_PATH/code/ssd-resnet34/tensorrt/download_model.sh
fi

## Validate and Calibrate Models format and Images
cp $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map.txt $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map_ori.txt
shuf -n 2000 $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map_ori.txt > $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map.txt
cat $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map.txt | wc -l
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/ssd-resnet34/tensorrt/preprocess_data.py --cal_only
python3 $INFERENCE_NVIDIA_PATH/code/ssd-resnet34/tensorrt/preprocess_data.py

## Execute MLPerf Benchmark
cd $INFERENCE_NVIDIA_PATH
make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=SingleStream --test_mode=PerformanceOnly"
make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=Offline --test_mode=PerformanceOnly"