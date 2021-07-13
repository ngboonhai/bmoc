#set -eo pipefail

python3 -m venv resnet50
source resnet50/bin/activate

CUR_DIR=`pwd`
BUILD_DIRECTORY=${CUR_DIR}

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
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/mlperf.conf ${CUR_DIR}/Configs/
    echo -e "\e[0;32m Copied default configudation to Configs directory!!\e[0m"
else
    echo -e "\e[0;32m Existing deafult configudation detected!!\e[0m"
fi
echo ${SKIPS}

##  Check and ready Resnet50 MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/resnet50 ]; then
    mkdir -p ${CUR_DIR}/Configs/resnet50
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/resnet50/config/* ${CUR_DIR}/Configs/resnet50/
    echo -e "\e[0;32m Copied Resnet50 mlperf configudation to current working directory!!\e[0m"
else
    echo -e "\e[0;32m Existing Resnet50 mlperf configudation detected!!\e[0m"
fi
echo ${SKIPS}

## Sanity check all the pre-work is ready before run mlperf benchmark task
if [ -d ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val ]; then
    echo -e "\e[0;32m Resnet50 imagenet datasets is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find resnet50 imagenet datasets!!\e[0m"
    echo -e "\e[0;31m System going to help to download resnet50 imagenet datasets, please wait... !!\e[0m"
    ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/resnet50/mlperf_benchmark_prework.sh
fi
echo ${SKIPS}

if [ -f ${CUR_DIR}/models/resnet50/resnet50_fp16.xml ]; then
    echo -e "\e[0;32m Resnet50 IR files is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find resnet50 IR file!!\e[0m"
    echo -e "\e[0;31m System going to help to run resnet50 IR file generation, please wait...!!\e[0m"
    ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/resnet50/mlperf_benchmark_prework.sh
fi
echo ${SKIPS}

## Config mlperf benchmark scenario and Test mode default values
SCENARIO=$1
if [ "${SCENARIO}" == "" ]; then
    SCENARIO="SingleStream"
else
    SCENARIO=${SCENARIO}
fi

PRECISION=$2
if [ "${PRECISION}" == "" ]; then
    PRECISION="int8"
else
    PRECISION=${PRECISION}
fi

## Run MLPerf benchmark for Resnet50 model
./run_mlperf.sh Configs/resnet50/${SCENARIO}-${PRECISION}-config.json
