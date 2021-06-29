#set -eo pipefail
set -x

CUR_DIR=`pwd`
SKIPS=" "

## Source system environment
source setup_envs.sh

## Sanity Check and copy mlperf python scripts
if [ ! -f ${CUR_DIR}/run_mlperf.sh ]; then
	cp ${CUR_DIR}/bmoc/cm/mpoc/intel/scrips/* ${CUR_DIR}/
	echo -e "\e[0;32m Copied mlperf scripts to directory!!\e[0m"
else
    echo -e "\e[0;32m Existing mlperf scripts detected!!\e[0m"
fi
echo ${SKIPS}

##  Check over all default MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/mlperf.conf ]; then
    mkdir -p ${CUR_DIR}/Configs
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v0.7/mlperf.conf ${CUR_DIR}/Configs/
    echo -e "\e[0;32m Copied default configudation to Configs directory!!\e[0m"
else
    echo -e "\e[0;32m Existing deafult configudation detected!!\e[0m"
fi
echo ${SKIPS}

##  Check and ready ssd-mobilenet MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/ssd-mobilenet ]; then
    mkdir -p ${CUR_DIR}/Configs/ssd-mobilenet
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v0.7/ssd-mobilenet/config/* ${CUR_DIR}/Configs/ssd-mobilenet/
    echo -e "\e[0;32m Copied ssd-mobilenet mlperf configudation to current working directory!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-mobilenet mlperf configudation detected!!\e[0m"
fi
echo ${SKIPS}

## Sanity check all the pre-work is ready before run mlperf benchmark task
if [ -d ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val ]; then
    echo -e "\e[0;32m ssd-mobilenet imagenet datasets is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find ssd-mobilenet imagenet datasets!!\e[0m"
    echo -e "\e[0;31m System going to help to download ssd-mobilenet imagenet datasets, please wait... !!\e[0m"
    ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v0.7/ssd-mobilenet/mlperf_benchmark_prework.sh
fi
echo ${SKIPS}

if [ -f ${CUR_DIR}/models/ssd-mobilenet/ssd-mobilenet_fp16.xml ]; then
    echo -e "\e[0;32m ssd-mobilenet IR files is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find ssd-mobilenet IR file!!\e[0m"
    echo -e "\e[0;31m System going to help to run ssd-mobilenet IR file generation, please wait...!!\e[0m"
    ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v0.7/ssd-mobilenet/mlperf_benchmark_prework.sh
fi
echo ${SKIPS}

## Config mlperf benchmark scenario and Test mode default values
SCENARIO=$1
if [ "${SCENARIO}" == "" ]; then
    SCENARIO="SingleStream"
else}
    SCENARIO=${SCENARIO}
fi

PRECISION=$2
if [ "${PRECISION}" == "" ]; then
    PRECISION="int8"
else
    PRECISION=${SCENARIO}
fi

## Run MLPerf benchmark for ssd-mobilenet model
./run_mlperf.sh Configs/ssd-mobilenet/${SCENARIO}-${PRECISION}-config.json
