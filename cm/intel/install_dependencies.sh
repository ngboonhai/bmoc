#set -eo pipefail

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
SKIPS=" "
DASHES="================================================"

echo ${SKIPS}
echo -e "\e[0;34m ========= Check and installing workload dependencis ========= \e[0m"
echo ${SKIPS}

sudo apt-get update
sudo apt install -y python3-opencv nvidia-cuda-toolkit jq
sudo python3 -m pip install networkx defusedxml progress
sudo python3 -m pip install requests --upgrade
sudo chmod a+r /usr/lib/x86_64-linux-gnu/libcuda*

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Toolkit for Benchmark Tools=========== \e[0m"
echo ${SKIPS}
	
if [ ! -d /opt/intel/openvino_2021 ]; then
	wget https://ubit-artifactory-sh.intel.com/artifactory/esc-local/utils/l_openvino_toolkit_p_2021.3.394.tgz
	tar xvf l_openvino_toolkit_p_2021.3.394.tgz
	cat ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/silent.cfg > l_openvino_toolkit_p_2021.3.394/silent.cfg
	cd l_openvino_toolkit_p_2021.3.394
	sudo ./install.sh -s silent.cfg
	cd ${CUR_DIR}
	rm -rf l_openvino_toolkit_p_2021.3.394*
	sudo ln -sf /opt/intel/openvino_2021.3.394 /opt/intel/openvino
	source /opt/intel/openvino_2021/bin/setupvars.sh
	echo -e "\e[0;32m Cmake ${cmake_version} installed!!\e[0m"

	echo -e "\e[0;34m ========== Installing OpenVino Toolkit Dependencies on system =========== \e[0m"
	sudo bash -E /opt/intel/openvino/install_dependencies/install_openvino_dependencies.sh -y

	echo -e "\e[0;34m ========== Installing OpenVino Toolkit Dependencies on system =========== \e[0m"
	sudo bash -E /opt/intel/openvino/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh

	echo -e "\e[0;32m ========== OpenVino Toolkit & Dependencies install completed =========== \e[0m"
else
	echo -e "\e[0;32m Existing OpenVino Toolkit & Dependencies detected!!\e[0m"
fi
echo ${SKIPS}

echo -e "\e[0;32m ========== Dependencies install completed =========== \e[0m"
