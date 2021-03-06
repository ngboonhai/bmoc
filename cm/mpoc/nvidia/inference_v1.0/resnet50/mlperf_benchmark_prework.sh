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
if [ ! -d $MLPERF_SCRATCH_PATH/data/imagenet ]; then
    mkdir -p $MLPERF_SCRATCH_PATH/data/imagenet
    wget https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar
    tar xf ILSVRC2012_img_val.tar -C $MLPERF_SCRATCH_PATH/data/imagenet
    rm $INFERENCE_NVIDIA_PATH/ILSVRC2012_img_val.tar
fi 

## Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/resnet50/tensorrt/download_data.sh

## Download Onnx Model from Zenodo Org.
if [ ! -d $MLPERF_SCRATCH_PATH/models/ResNet50/resnet50_v1.onnx ]; then
    cd $INFERENCE_NVIDIA_PATH
    bash $INFERENCE_NVIDIA_PATH/code/resnet50/tensorrt/download_model.sh
fi

## Validate and Calibrate Models format and Images
cp $INFERENCE_NVIDIA_PATH/data_maps/imagenet/val_map.txt $INFERENCE_NVIDIA_PATH/data_maps/imagenet/val_map_ori.txt
shuf -n 2000 $INFERENCE_NVIDIA_PATH/data_maps/imagenet/val_map_ori.txt > $INFERENCE_NVIDIA_PATH/data_maps/imagenet/val_map.txt
cat $INFERENCE_NVIDIA_PATH/data_maps/imagenet/val_map.txt | wc -l
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/resnet50/tensorrt/preprocess_data.py --cal_only
python3 $INFERENCE_NVIDIA_PATH/code/resnet50/tensorrt/preprocess_data.py