#set -eo pipefail
set -x

CUR_DIR=`pwd`

##  Check and ready Resnet50 MLPerf configuration files.
if [ ! -d ${CUR_DIR}/Configs/resnet50 ]; then
	mkdir -p ${CUR_DIR}/Configs/resnet50
	cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/resnet50/config/* ${CUR_DIR}/Configs/resnet50/
	echo -e "\e[0;31m Copied Resnet50 mlperf configudation to current working directory!!\e[0m"
else
	echo -e "\e[0;31m Existing Resnet50 mlperf configudation detected!!\e[0m"
fi

