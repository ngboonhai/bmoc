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

## Perform dataset download.
cd $INFERENCE_NVIDIA_PATH
bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_data.sh
if [ -f $MLPERF_SCRATCH_PATH/data/coco/*.zip ]; then
    rm $MLPERF_SCRATCH_PATH/data/coco/*.zip
fi

## Download Onnx Model from Zenodo Org.
if [ ! -f $MLPERF_SCRATCH_PATH/models/SSDMobileNet/frozen_inference_graph.pb ]; then
    cd $INFERENCE_NVIDIA_PATH $MLPERF_SCRATCH_PATH
    bash $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/download_model.sh
fi

## Validate and Calibrate Models format and Images
cp $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map.txt $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map_ori.txt
shuf -n 2000 $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map_ori.txt > $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map.txt
cat $INFERENCE_NVIDIA_PATH/data_maps/coco/val_map.txt | wc -l
cd $INFERENCE_NVIDIA_PATH
python3 $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/preprocess_data.py --cal_only
python3 $INFERENCE_NVIDIA_PATH/code/ssd-mobilenet/tensorrt/preprocess_data.py
