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

## Set NVIDIA Mlperf scratch path as envrionment variable
grep -Rn "$MLPERF_SCRATCH_PATH" ~/.bashrc
[ "$?" -ne "0" ] && echo "export INFERENCE_NVIDIA_PATH=$INFERENCE_NVIDIA_PATH" >> ~/.bashrc && echo "export MLPERF_SCRATCH_PATH=$MLPERF_SCRATCH_PATH" >> ~/.bashrc
source ~/.bashrc
export | grep $INFERENCE_NVIDIA_PATH


## Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_data.sh


## Download Onnx Model from Zenodo Org.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_model.sh


## Validate and Calibrate Models format and Images
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/preprocess_data.py --cal_only
python3 $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/preprocess_data.py
