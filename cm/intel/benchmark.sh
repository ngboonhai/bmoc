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

for benchmark_run in {1..3}
do
	python3 /opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m ${MODEL_FILE_PATH} -d CPU -i /workload/benchmar/datasets/ -b 1 -progress true
	echo "Precision: $PRECISION"
	if [ $(($benchmark_run)) -lt 2 ]; then
		echo ${SKIPS}
		printf "\e[6;33m                =============== Completed numner of run: $(($benchmark_run)) of 3 =============== \e[0m"
		printf "\e[6;33m                ======   Next running will start in another 30 seconds   ====== \e[0m"
		#echo  -e "\033[33;5;7m                =============== Completed numner of run: $(($benchmark_run)) of 3 =============== \033[0m"
		#echo  -e "\033[33;5;7m                ======   Next running will start in another 30 seconds   ====== \033[0m"
		#echo -e "\e[0;32m                =============== Completed numner of run: $(($benchmark_run)) of 3 =============== \e[0m"
		#echo -e "\e[0;32m                ======   Next running will start in another 30 seconds   ====== \e[0m"
		echo ${SKIPS}
		sleep 30s
	else
		echo -e "\e[0;32m =============== Completed number of run: $(($benchmark_run)) of 3 =============== \e[0m"
	fi
done

echo -e "\e[0;32m ====== Benchmark for ${MODEL} is completed ====== \e[0m"
echo ${SKIPS}
