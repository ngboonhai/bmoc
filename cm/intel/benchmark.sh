#set -eo pipefail

SKIPS=" "
DASHES="================================================"

error() {
    local code="${3:-1}"
    if [[ -n "$2" ]];then
        echo "Error on or near line $1: $2; exiting with status ${code}"
    else
        echo "Error on or near line $1; exiting with status ${code}"
    fi
    exit "${code}"
}
trap 'error ${LINENO}' ERR

CUR_DIR=`pwd`
BUILD_DIRECTORY=${CUR_DIR}

## Configure of benchmark scenario and precision default values
MODEL=$1
if [ "${MODEL}" == "" ]; then
    echo -e "\e[0;31m [Error}: Model name is require for benchmarking !!! \e[0m"
	exit 1
else
    MODEL=${MODEL}
fi

PRECISION=$2
if [ "${PRECISION}" == "" ]; then
    PRECISION="fp16"
else
    PRECISION=${PRECISION}
fi

source /opt/intel/openvino_2021/bin/setupvars.sh
export PATH=/usr/lib/x86_64-linux-gnu${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

echo ${SKIPS}
echo -e "\e[0;34m ========= Start running benchmark for ${MODEL} ========= \e[0m"
echo ${SKIPS}

MODEL_DIR=`find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
python3 /opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m ${MODEL_DIR}/${MODEL}_${PRECISION}.xml -d CPU -i /workload/benchmar/datasets/ -b 1 -progress true

echo ${SKIPS}
echo -e "\e[0;32m ========= Benchmark for ${MODEL} is completed ========= \e[0m"
echo ${SKIPS}
