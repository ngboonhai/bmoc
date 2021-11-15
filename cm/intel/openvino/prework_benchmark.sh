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

error_model_optimizing()
{
  	echo -e "\e[0;31m    [ERROR]: Unable to optimize the model !!! \e[0m" 1>&2
	echo ${SKIPS}
  	exit 1
}

error_model_quantizaring()
{
	rm -rf ${CUR_DIR}/${MODEL_DIR}
  	echo -e "\e[0;31m    [ERROR]: Unable to quantize the model !!! \e[0m" 1>&2
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

#echo ${SKIPS}
#echo -e "\e[0;34m ========= Downloading benchmark imagenet datasets ========= \e[0m"
#echo ${SKIPS}
#if [ ! -d ${CUR_DIR}/datasets/input_images ]; then
#	mkdir -p ${CUR_DIR}/datasets
#	wget http://pgluint99.png.intel.com:8080//workload_installer/linux_benchmark/dataset/input_images.zip
#	unzip -q -o -d ${CUR_DIR}/datasets input_images.zip
#	echo -e "\e[0;32m ========== Benchmark imagenet datasets download and extract completed =========== \e[0m"
#else
#	echo -e "\e[0;32m Existing benchmark dataests detected!!\e[0m"
#fi
#echo ${SKIPS}

## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/val2017 ]; then
    wget http://images.cocodataset.org/zips/val2017.zip
    wget http://images.cocodataset.org/annotations/annotations_trainval2017.zip
    unzip val2017.zip -d ${CUR_DIR}/datasets/
    unzip annotations_trainval2017.zip -d ${CUR_DIR}/datasets/
    cp ${CUR_DIR}/datasets/annotations/instances_val2017.json ${CUR_DIR}/datasets
    rm ${CUR_DIR}/val2017.zip ${CUR_DIR}/annotations_trainval2017.zip
    echo -e "\e[0;32m ========== Benchmark coco_2017  datasets download and extract completed =========== \e[0m"
else
    echo -e "\e[0;32m Exisitng coco_2017 datasets detected!!\e[0m"
fi
echo ${SKIPS}

## Download dataset from Image-net Org for Quantify Model files
if [ ! -d ${CUR_DIR}/datasets/ILSVRC2012_img_val ]; then
    mkdir -p ${CUR_DIR}/datasets/ILSVRC2012_img_val
    wget https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar
    tar xf ILSVRC2012_img_val.tar -C ${CUR_DIR}/datasets/ILSVRC2012_img_val/
    rm ${CUR_DIR}/ILSVRC2012_img_val.tar
    cp ${CUR_DIR}/cm/performance/ai/openvino/val.txt ${CUR_DIR}/datasets
fi

source /opt/intel/openvino_2021/bin/setupvars.sh
export PATH=/usr/lib/x86_64-linux-gnu${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

echo ${SKIPS}
echo -e "\e[0;34m ========= Downloading benchmark models ========= \e[0m"
echo ${SKIPS}
MODEL_DIR_DETECTED=`sudo find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
if [ "${MODEL_DIR_DETECTED}" == "" ]; then
	mkdir -p ${CUR_DIR}/models
	python3 /opt/intel/openvino_2021/deployment_tools/open_model_zoo/tools/downloader/downloader.py --name ${MODEL} 2>/dev/null || error_model_finding
	MODEL_DIR=`sudo find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
else
	MODEL_DIR=`sudo find ${CUR_DIR} -type d -name "${MODEL}"  2>/dev/null`
	echo -e "\e[0;32m Existing benchmark models detected!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========= Optimize and quantify benchmark models ========= \e[0m"
echo ${SKIPS}
IR_FILE_PATH=`sudo find ${MODEL_DIR} -name "*.xml" 2>/dev/null`
if [ ! "${IR_FILE_PATH}" == "" ]; then
	for file_path in `echo $IR_FILE_PATH`
	do
		if [[ $file_path =~ "FP16-INT8" ]]; then
			MODEL_FILE_PATH=$file_path
			FOUND="true"
			echo -e "\e[0;32m IR files of ${MODEL} has been ready to benchmark \e[0m"
			echo ${SKIPS} 
			break
		elif [[ $file_path =~ "FP16" ]]; then
			MODEL_FILE_PATH=$file_path
			FOUND="true"
			echo -e "\e[0;32m IR files of ${MODEL} has been ready to benchmark \e[0m"
			echo ${SKIPS} 
			break
		elif [[ $file_path =~ "FP32" ]]; then
			MODEL_FILE_PATH=$file_path
			FOUND="true"
			echo -e "\e[0;32m IR files of ${MODEL} has been ready to benchmark \e[0m"
			echo ${SKIPS} 
			break
		fi
			if [ ! $FOUND == "true" ]; then
		       echo -e "\e[0;31m The INT8 of IR file for the ${MODEL} not detected or generated from Opensource before \e[0m"
		       exit 1
		fi
		echo ${SKIPS} 
	done
else
	echo ${SKIPS}
	echo -e "\e[0;34m ========= Optimizing models ========= \e[0m"
	echo ${SKIPS}
	/opt/intel/openvino_2021/deployment_tools/open_model_zoo/tools/downloader/converter.py --name ${MODEL} 2>/dev/null || error_model_optimizing
	
	echo ${SKIPS}
	echo -e "\e[0;34m ========= quantifing benchmark models ========= \e[0m"
	echo ${SKIPS}
	/opt/intel/openvino_2021/deployment_tools/open_model_zoo/tools/downloader/quantizer.py --name ${MODEL} --dataset_dir ${CUR_DIR}/datasets/ \
	2>/dev/null || error_model_quantizaring
	
	echo -e "\e[0;32m ========== Benchmark models has been optimized, INT8 IR files generated =========== \e[0m"
fi
