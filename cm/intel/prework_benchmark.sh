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

error_model_finding()
{
  	echo -e "\e[0;31m    [ERROR]: Benchmark models not found !!! \e[0m" 1>&2
	echo ${SKIPS}
  	exit 1
}

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

echo ${SKIPS}
echo -e "\e[0;34m ========= Preparing benchmark configuration file ========= \e[0m"
echo ${SKIPS}
if [ ! -f ${CUR_DIR}/Configs/models_config.json ]; then
	mkdir -p ${CUR_DIR}/Configs
	cp bmoc/cm/intel/models_config.json ${CUR_DIR}/Configs/
	echo -e "\e[0;32m ========== Copied benchmark configuration file =========== \e[0m"
else
	echo -e "\e[0;32m Existing benchmark configuration file detected!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========= Downloading benchmark datasets ========= \e[0m"
echo ${SKIPS}
if [ ! -d /workload/benchmark/datasets/input_images ]; then
	mkdir -p ${CUR_DIR}/datasets
	wget https://ubit-artifactory-sh.intel.com/artifactory/esc-local/utils/input_images.zip
	unzip -d ${CUR_DIR}/datasets input_images.zip
	echo -e "\e[0;32m ========== Benchmark dataest download and extract completed =========== \e[0m"
else
	echo -e "\e[0;32m Existing benchmark dataests detected!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========= Downloading benchmark models ========= \e[0m"
echo ${SKIPS}
MODEL_DIR_DETECTED=`find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
if [ "${MODEL_DIR_DETECTED}" == "" ]; then
	mkdir -p ${CUR_DIR}/models
	python3 /opt/intel/openvino_2021/deployment_tools/open_model_zoo/tools/downloader/downloader.py --name ${MODEL} -o ${CUR_DIR}/models/ 2>/dev/null || error_model_finding
	MODEL_DIR=`find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
else
	MODEL_DIR=`find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
	echo -e "\e[0;32m Existing benchmark models detected!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========= Optimizing benchmark models ========= \e[0m"
echo ${SKIPS}
IR_FILE_PATH=`find ${MODEL_DIR} -name "*.xml" 2>/dev/null`
if [ ! "${IR_FILE_PATH}" == "" ]; then
	for file_path in `echo $IR_FILE_PATH`
       	do
		if [[ $file_path =~ "FP16-INT8" ]]; then
			MODEL_FILE_PATH=$file_path
			FOUND="true"
			break
		elif [[ $file_path =~ "FP16" ]]; then
			MODEL_FILE_PATH=$file_path
			FOUND="true"
			break
		elif [[ $file_path =~ "FP32" ]]; then
			MODEL_FILE_PATH=$file_path
			FOUND="true"
			break
		fi
		
		if [ ! $FOUND == "true" ]; then
		       echo -e "\e[0;31m The INT8 of IR file for the ${MODEL} not detected or generated from Opensource before \e[0m"
		       exit 1
		else
			echo -e "\e[0;32m IR files of ${MODEL} has been ready to benchmark \e[0m"
		fi
	done
else
	MODEL_FIND=`jq -r '."'"${MODEL}"'"' ${CUR_DIR}/Configs/models_config.json`
	if [ ! "${MODEL_FIND}" == null ]; then
		MODEL_FILE=`jq -r '."'"${MODEL}"'"'.model_file ${CUR_DIR}/Configs/models_config.json`
		FRAME_WORK=`jq -r '."'"${MODEL}"'"'.frame_work ${CUR_DIR}/Configs/models_config.json`
		MODEL_FILE_PATH=`find ${MODEL_DIR} -name $MODEL_FILE`
		case ${FRAME_WORK} in
			caffe)
			FRAME_WORK_TOOL=mo_caffe.py
			;;
			onnx)
			FRAME_WORK_TOOL=mo_onnx.py
			;;
			tensorflow)
			FRAME_WORK_TOOL=mo_tf.py
			;;
			*)
			FRAME_WORK_TOOL=mo.py
			;;
		esac
		echo -e "\e[0;32m Loaded ${MODEL} configuration from models_condif.json file. Optimizing the model now... \e[0m"
	else
		echo -e "\e[0;31m Benchmark models yet add into models_condif.json file, please check !!! \e[0m"
		exit 1
	fi
	echo ${SKIPS} 	
	
	python3 /opt/intel/openvino_2021/deployment_tools/model_optimizer/${FRAME_WORK_TOOL} --input_model ${MODEL_FILE_PATH} --data_type FP16 --output_dir ${MODEL_DIR} --model_name ${MODEL}_${PRECISION}
	echo ${SKIPS} 
	echo -e "\e[0;32m ========== Benchmark models has been optimized and IR files generated =========== \e[0m"
fi
