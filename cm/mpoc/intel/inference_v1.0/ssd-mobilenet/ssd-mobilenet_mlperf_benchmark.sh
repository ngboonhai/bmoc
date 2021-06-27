#set -eo pipefail
set -x

CUR_DIR=`pwd`

##  Check over all default MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/mlperf.conf ]; then
    mkdir -p ${CUR_DIR}/Configs
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/mlperf.conf ${CUR_DIR}/Configs/
    echo -e "\e[0;32m Copied default configudation to Configs directory!!\e[0m"
else
    echo -e "\e[0;32m Existing deafult configudation detected!!\e[0m"
fi


##  Check and ready ssd-mobilenet MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/ssd-mobilenet ]; then
    mkdir -p ${CUR_DIR}/Configs/ssd-mobilenet
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/ssd-mobilenet/config/* ${CUR_DIR}/Configs/ssd-mobilenet/
    echo -e "\e[0;32m Copied ssd-mobilenet mlperf configudation to current working directory!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-mobilenet mlperf configudation detected!!\e[0m"
fi

## Sanity check all the pre-work is ready before run mlperf benchmark task
if [ ! -f ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val/ ]; then
    echo -e "\e[0;32m ssd-mobilenet imagenet datasets is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find ssd-mobilenet imagenet datasets, please check!!\e[0m"
    exit 1
fi

if [ ! -f ${CUR_DIR}/models/ssd-mobilenet/ssd-mobilenet_fp16.xml ]; then
    echo -e "\e[0;32m ssd-mobilenet IR files is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find ssd-mobilenet IR file, please check!!\e[0m"
    exit 1
fi

## Config mlperf benchmark scenario and Test mode default values
SCENARIO=$1
if [ "${SCENARIO}" == "" ]; then
    SCENARIO="SingleStream"
else}
    SCENARIO=${SCENARIO}
fi

## Run MLPerf benchmark for ssd-mobilenet model
bash run_mlperf.sh Configs/ssd-mobilenet/${SCENARIO}-config.json
