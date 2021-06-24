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
cat bmoc/cm/mpoc/nvidia/inference_v1.0/3d-unet/Makefile > $INFERENCE_NVIDIA_PATH/Makefile
cat bmoc/cm/mpoc/nvidia/inference_v1.0/lwis_buffers.h > $INFERENCE_NVIDIA_PATH/code/harness/lwis/include/lwis_buffers.h
cat bmoc/cm/mpoc/nvidia/inference_v1.0/preprocess_data.py > $INFERENCE_NVIDIA_PATH/code/3d-unet/tensorrt/preprocess_data.py

## Dependencies only for Jetson system
sudo apt-get update
sudo apt-get install -y python-dev python3-dev python-pip python3-pip curl libopenmpi2
sudo python -m pip install absl-py
sudo python3 -m pip install scikit-build astunparse
bash $INFERENCE_NVIDIA_PATH/scripts/install_xavier_dependencies.sh

# Re-check and install ONNX preprocessing again.
sudo python -m pip install numpy==1.16.4
sudo python3 -m pip install onnx==1.7.0
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

## Execute MLPerf Benchmark
#export PREPROCESSED_DATA_DIR="build/preprocessed_data"
sudo python3 -m pip install onnx==1.7.0
cd $INFERENCE_NVIDIA_PATH
make run RUN_ARGS="--benchmarks=3d-unet --scenarios=SingleStream --config_ver=default --test_mode=PerformanceOnly"
make run RUN_ARGS="--benchmarks=3d-unet --scenarios=Offline --config_ver=default --test_mode=PerformanceOnly"
