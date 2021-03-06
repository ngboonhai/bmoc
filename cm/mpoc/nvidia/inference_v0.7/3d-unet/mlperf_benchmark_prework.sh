#set -eo pipefail
set -x

## Variable declaration
MLPERF_INFERENCE_REPO="inference_results_v0.7"
INFERENCE_NVIDIA_PATH=~/inference_results_v0.7/closed/NVIDIA
MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build

## Checkout MLPerf Inference v0.7 repo from GitHub
[ ! -d "$MLPERF_INFERENCE_REPO" ] && git clone https://github.com/mlcommons/$MLPERF_INFERENCE_REPO.git ~/$MLPERF_INFERENCE_REPO

## Create NVIDIA MLPerf scratch path
[ ! -d "$MLPERF_SCRATCH_PATH" ] && mkdir -p $MLPERF_SCRATCH_PATH

## Check and Set NVIDIA Mlperf scratch path as envrionment variable
[[ ! -z `export | grep INFERENCE_NVIDIA_PATH` ]] && echo $INFERENCE_NVIDIA_PATH || export INFERENCE_NVIDIA_PATH=$INFERENCE_NVIDIA_PATH
[[ ! -z `export | grep MLPERF_SCRATCH_PATH` ]] && echo $MLPERF_SCRATCH_PATH || export MLPERF_SCRATCH_PATH=$INFERENCE_NVIDIA_PATH/build
export | grep $INFERENCE_NVIDIA_PATH

## Sanity check exisitng dependecies and Additional dependecies install require due to version not competible for preporcess data steps
sudo python3 -m pip install numpy==1.16.4 pandas
sudo python3 -m pip install batchgenerators
cd /tmp
wget -O torch-1.7.0-cp36-cp36m-linux_aarch64.whl https://nvidia.box.com/shared/static/cs3xn3td6sfgtene6jdvsxlr366m2dhq.whl
sudo python3 -m pip install torch-1.7.0-cp36-cp36m-linux_aarch64.whl
sudo python3 -m pip install nnunet

## Download dataset from Image-net Org.
if [ ! -d $MLPERF_SCRATCH_PATH/data/BraTS/MICCAI_BraTS_2019_Data_Training ]; then
    mkdir -p $MLPERF_SCRATCH_PATH/data/BraTS
    curl -L -O https://www.cbica.upenn.edu/sbia/Spyridon.Bakas/MICCAI_BraTS/2019/MICCAI_BraTS_2019_Data_Training.zip
    unzip MICCAI_BraTS_2019_Data_Training.zip -d $MLPERF_SCRATCH_PATH/data/BraTS
    rm MICCAI_BraTS_2019_Data_Training.zip 
fi

## Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/download_data.sh

## Download Onnx Model from Zenodo Org.
if [ ! -f $MLPERF_SCRATCH_PATH/models/3d-unet/3dUNetBraTS.onnx ]; then
    cd $INFERENCE_NVIDIA_PATH
    bash $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/download_model.sh
fi

## Sanity check exisitng dependecies and Additional dependecies install require due to version not competible for preporcess data steps
sudo apt-get install -y libatlas-base-dev gfortran
sudo python3 -m pip install numpy==1.16.4 pandas
sudo python3 -m pip install batchgenerators
cd /tmp
wget -O torch-1.7.0-cp36-cp36m-linux_aarch64.whl https://nvidia.box.com/shared/static/cs3xn3td6sfgtene6jdvsxlr366m2dhq.whl
sudo python3 -m pip install torch-1.7.0-cp36-cp36m-linux_aarch64.whl
sudo python3 -m pip install nnunet

## Validate and Calibrate Models format and Images
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/preprocess_data.py
