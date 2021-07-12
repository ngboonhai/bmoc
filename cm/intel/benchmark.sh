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

DEVICE=$2
if [ "${DEVICE}" == "" ]; then
    DEVICE="CPU"
else
    DEVICE=${DEVICE}
fi

BATCH_SIZE=$3
if [ "${BATCH_SIZE}" == "" ]; then
    BATCH_SIZE=1
else
    BATCH_SIZE=${BATCH_SIZE}
fi

source /opt/intel/openvino_2021/bin/setupvars.sh
export PATH=/usr/lib/x86_64-linux-gnu${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

echo ${SKIPS}
echo -e "\e[0;34m ========= Start running benchmark for ${MODEL} ========= \e[0m"
echo ${SKIPS}

FOUND="false"
MODEL_DIR=`find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
IR_FILE_PATH=`find ${MODEL_DIR} -name "*.xml" 2>/dev/null`
if [ ! "${IR_FILE_PATH}" == "" ]; then
        for file_path in `echo $IR_FILE_PATH`
        do
		if [[ $file_path =~ "INT8" || $file_path =~ "int8" ]]; then
                        MODEL_FILE_PATH=$file_path
			PRECISION="INT8"
                        FOUND="true"
			break
		elif [[ ( $file_path =~ "FP16" || $file_path =~ "fp16" ) ]]; then
			MODEL_FILE_PATH=$file_path
			PRECISION="FP16"
                        FOUND="true"
			break
                fi
		continue
		
                if [ ! $FOUND == "true" ]; then
                       echo -e "\e[0;31m Unable to find any of IR file for the ${MODEL} not detected or generated from Opensource before \e[0m"
		       exit 1
                fi
        done

fi 

IFS=","
for BATCH_VALUE in ${BATCH_SIZE}
do
	for benchmark_run in {1..3}
	do
		python3 /opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m ${MODEL_FILE_PATH} -d ${DEVICE} -i /workload/benchmar/datasets/ -b ${BATCH_VALUE} -progress true
		echo "Precision: $PRECISION"
		echo "Batch Size: ${BATCH_VALUE}"
		if [ $(($benchmark_run)) -lt 3 ]; then
			echo ${SKIPS}
			echo  -e "\033[33;5m                =============== Completed numner of run: $(($benchmark_run)) of 3 =============== \033[0m"
			echo  -e "\033[33;5m                ======   Next running will start in another 30 seconds   ====== \033[0m"
			echo ${SKIPS}
			sleep 30s
		else
			echo -e "\e[0;32m                =============== Completed number of run: $(($benchmark_run)) of 3 =============== \e[0m"
		fi
	done
done
echo -e "\e[0;32m                ====== Benchmark for ${MODEL} is completed ====== \e[0m"
echo ${SKIPS}
