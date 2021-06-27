#set -eo pipefail
set -x

CUR_DIR=`pwd`
SKIPS=" "

##  Check over all default MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/mlperf.conf ]; then
    mkdir -p ${CUR_DIR}/Configs
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/mlperf.conf ${CUR_DIR}/Configs/
    echo -e "\e[0;32m Copied default configudation to Configs directory!!\e[0m"
else
    echo -e "\e[0;32m Existing deafult configudation detected!!\e[0m"
fi
echo ${SKIPS}

##  Check and ready ssd-resnet34 MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/ssd-resnet34 ]; then
    mkdir -p ${CUR_DIR}/Configs/ssd-resnet34
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/ssd-resnet34/config/* ${CUR_DIR}/Configs/ssd-resnet34/
    echo -e "\e[0;32m Copied ssd-resnet34 mlperf configudation to current working directory!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-resnet34 mlperf configudation detected!!\e[0m"
fi
echo ${SKIPS}

## Sanity check all the pre-work is ready before run mlperf benchmark task
if [ -d ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val ]; then
    echo -e "\e[0;32m ssd-resnet34 imagenet datasets is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find ssd-resnet34 imagenet datasets, please check!!\e[0m"
    exit 1
fi
echo ${SKIPS}

if [ -f ${CUR_DIR}/models/ssd-resnet34/ssd-resnet34_fp16.xml ]; then
    echo -e "\e[0;32m ssd-resnet34 IR files is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find ssd-resnet34 IR file, please check!!\e[0m"
    exit 1
fi
echo ${SKIPS}

## Config mlperf benchmark scenario and Test mode default values
SCENARIO=$1
if [ "${SCENARIO}" == "" ]; then
    SCENARIO="SingleStream"
else
    SCENARIO=${SCENARIO}
fi

## Run MLPerf benchmark for ssd-resnet34 model
bash run_mlperf.sh Configs/ssd-resnet34/${SCENARIO}-config.json
