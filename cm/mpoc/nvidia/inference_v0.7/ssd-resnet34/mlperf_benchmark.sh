#set -eo pipefail
set -x

git clone https://github.com/mlcommons/inference_results_v0.7.git ~/inference_results_v0.7
INFERENCE_NVIDIA_PATH=~/inference_results_v0.7/closed/NVIDIA
MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build
mkdir -p $MLPERF_SCRATCH_PATH
echo "export INFERENCE_NVIDIA_PATH=$INFERENCE_NVIDIA_PATH" >> ~/.bashrc
echo "export MLPERF_SCRATCH_PATH=$MLPERF_SCRATCH_PATH" >> ~/.bashrc
source ~/.bashrc
export | grep $INFERENCE_NVIDIA_PATH


## Update some files which errors detect from Origical files from Repo
cat bmoc/cm/mpoc/nvidia/inference_v0.7/install_xavier_dependencies.sh > $INFERENCE_NVIDIA_PATH/scripts/install_xavier_dependencies.sh
cat bmoc/cm/mpoc/nvidia/inference_v0.7/Makefile > $INFERENCE_NVIDIA_PATH/Makefile
cat bmoc/cm/mpoc/nvidia/inference_v0.7/lwis_buffers.h > $INFERENCE_NVIDIA_PATH/code/harness/lwis/include/lwis_buffers.h


## Dependencies only for Jetson system
sudo apt-get update
sudo apt-get install libopenmpi2
bash $INFERENCE_NVIDIA_PATH/scripts/install_xavier_dependencies.sh

## Build TensorRT and MLPerf Plugins
cd $INFERENCE_NVIDIA_PATH
make clone_loadgen
#make build_plugins
make build_loadgen
make build_harness


## Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/ssd-resnet34/tensorrt/download_data.sh


## Download Onnx Model from Zenodo Org.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/ssd-resnet34/tensorrt/download_model.sh


## Validate and Calibrate Models format and Images
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/ssd-resnet34/tensorrt/preprocess_data.py


## Execute MLPerf Benchmark
make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=SingleStream --test_mode=PerformanceOnly"
make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=SingleStream --test_mode=AccuracyOnly"
# make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=MultiStream --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=MultiStream --test_mode=AccuracyOnly"
make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=Offline --test_mode=PerformanceOnly"
make run RUN_ARGS="--benchmarks=ssd-resnet34 --scenarios=Offline --test_mode=AccuracyOnly"
