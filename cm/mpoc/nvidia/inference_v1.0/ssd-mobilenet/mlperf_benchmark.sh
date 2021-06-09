#set -eo pipefail
set -x

git clone https://github.com/mlcommons/inference_results_v1.0.git ~/inference_results_v1.0
INFERENCE_NVIDIA_PATH=~/inference_results_v1.0/closed/NVIDIA
MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build
mkdir -p $MLPERF_SCRATCH_PATH
echo "export INFERENCE_NVIDIA_PATH=$INFERENCE_NVIDIA_PATH" >> ~/.bashrc
echo "export MLPERF_SCRATCH_PATH=$MLPERF_SCRATCH_PATH" >> ~/.bashrc
source ~/.bashrc
export | grep $INFERENCE_NVIDIA_PATH

## Dependencies only for Jetson system
bash $INFERENCE_NVIDIA_PATH/scripts/install_xavier_dependencies.sh

## Build TensorRT and MLPerf Plugins
cd $INFERENCE_NVIDIA_PATH
make clone_loadgen
make build_plugins
make build_loadgen
make build_harness

## Perform dataset download.
bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_data.sh


## Download Onnx Model from Zenodo Org.
bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_model.sh


## Validate and Calibrate Models format and Images
python3 $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/preprocess_data.py


## Execute MLPerf Benchmark
# make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=SingleStream --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=SingleStream --test_mode=AccuracyOnly"
# make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=MultiStream --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=MultiStream --test_mode=AccuracyOnly"
# make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=Offline --test_mode=PerformanceOnly"
# make run RUN_ARGS="--benchmarks=ssd-mobilenet --scenarios=Offline --test_mode=AccuracyOnly"