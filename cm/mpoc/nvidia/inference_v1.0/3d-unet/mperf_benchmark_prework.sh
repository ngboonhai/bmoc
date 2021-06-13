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

## Check and Set NVIDIA Mlperf scratch path as envrionment variable
[[ ! -z `export | grep INFERENCE_NVIDIA_PATH` ]] && echo $INFERENCE_NVIDIA_PATH || export INFERENCE_NVIDIA_PATH=~/inference_results_v1.0/closed/NVIDIA
[[ ! -z `export | grep MLPERF_SCRATCH_PATH` ]] && echo $MLPERF_SCRATCH_PATH || export MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build
export | grep $INFERENCE_NVIDIA_PATH

## Download dataset from Image-net Org.
mkdir -p $MLPERF_SCRATCH_PATH/data/BraTS
curl -L -O https://www.cbica.upenn.edu/sbia/Spyridon.Bakas/MICCAI_BraTS/2019/MICCAI_BraTS_2019_Data_Training.zip
unzip MICCAI_BraTS_2019_Data_Training.zip -d $MLPERF_SCRATCH_PATH/data/BraTS

## Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/download_data.sh

## Download Onnx Model from Zenodo Org.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/download_model.sh

## Validate and Calibrate Models format and Images
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/preprocess_data.py --cal_only
python3 $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/preprocess_data.py