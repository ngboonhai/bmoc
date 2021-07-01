#set -eo pipefail

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
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/mlperf.conf ${CUR_DIR}/Configs/
    echo -e "\e[0;32m Copied default configudation to Configs directory!!\e[0m"
else
    echo -e "\e[0;32m Existing deafult configudation detected!!\e[0m"
fi
echo ${SKIPS}

##  Check and ready 3d-unetMLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/3d-unet ]; then
    mkdir -p ${CUR_DIR}/Configs/3d-unet
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/config/* ${CUR_DIR}/Configs/3d-unet/
    echo -e "\e[0;32m Copied 3d-unetmlperf configudation to current working directory!!\e[0m"
else
    echo -e "\e[0;32m Existing 3d-unetmlperf configudation detected!!\e[0m"
fi
echo ${SKIPS}

## Sanity check all the pre-work is ready before run mlperf benchmark task
if [ -d ${CUR_DIR}/datasets/3d-unet/BraTS ]; then
    echo -e "\e[0;32m 3d-unetimagenet datasets is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find 3d-unetimagenet datasets!!\e[0m"
    echo -e "\e[0;31m System going to help to download 3d-unetimagenet datasets, please wait... !!\e[0m"
    ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/mlperf_benchmark_prework.sh
fi
echo ${SKIPS}

if [ -f ${CUR_DIR}/models/3d-unet/3d-unet_fp32.xml ]; then
    echo -e "\e[0;32m 3d-unetIR files is ready!!\e[0m"
else
    echo -e "\e[0;31m Unable to find 3d-unetIR file!!\e[0m"
    echo -e "\e[0;31m System going to help to run 3d-unetIR file generation, please wait...!!\e[0m"
    ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/mlperf_benchmark_prework.sh
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

## Run MLPerf benchmark for 3d-unetmodel
./run_mlperf.sh Configs/3d-unet/${SCENARIO}-${PRECISION}-config.json
