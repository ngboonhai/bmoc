#set -eo pipefail

SKIPS=" "
DASHES="================================================"
CUR_DIR=`pwd`
BUILD_DIRECTORY=${CUR_DIR}

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

echo ${SKIPS}
echo -e "\e[0;34m ========= Check and installing workload dependencis ========= \e[0m"
echo ${SKIPS}

sudo apt-get update
sudo apt install -y python3-dev python3-pip unzip python3-opencv nvidia-cuda-toolkit jq python3.8-venv libssl-dev

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Toolkit for Benchmark Tools=========== \e[0m"
echo ${SKIPS}	
if [ ! -d /opt/intel/openvino_2021 ]; then
	wget https://ubit-artifactory-sh.intel.com/artifactory/esc-local/utils/openvino/2021.3/l_openvino_toolkit_p_2021.3.394.tgz
	tar xvf l_openvino_toolkit_p_2021.3.394.tgz
	cat ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/silent.cfg > l_openvino_toolkit_p_2021.3.394/silent.cfg
	cd l_openvino_toolkit_p_2021.3.394
	sudo ./install.sh -s silent.cfg
	cd ${CUR_DIR}
	rm -rf l_openvino_toolkit_p_2021.3.394*
	source /opt/intel/openvino_2021/bin/setupvars.sh
	echo -e "\e[0;32m Cmake ${cmake_version} installed!!\e[0m"

	echo -e "\e[0;34m ========== Installing OpenVino Toolkit Dependencies on system =========== \e[0m"
	sudo bash -E /opt/intel/openvino_2021/install_dependencies/install_openvino_dependencies.sh -y

	echo -e "\e[0;32m ========== OpenVino Toolkit & Dependencies install completed =========== \e[0m"
else
	echo -e "\e[0;32m Existing OpenVino Toolkit & Dependencies detected!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing Cuda Toolkit for Benchmark Tools=========== \e[0m"
echo ${SKIPS}
DIST=$(. /etc/os-release && echo ${VERSION_CODENAME-stretch})
cuda_ver=`dpkg -l | grep 'CUDA Toolkit 11.4 meta-package' | awk '{print $3}'`
if [ -z $cuda_ver ] && [ "${DIST}" == "bionic" ]; then
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
	sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
	wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda-repo-ubuntu1804-11-4-local_11.4.0-470.42.01-1_amd64.deb
	sudo dpkg -i cuda-repo-ubuntu1804-11-4-local_11.4.0-470.42.01-1_amd64.deb
	sudo apt-key add /var/cuda-repo-ubuntu1804-11-4-local/7fa2af80.pub
	sudo apt-get update
	sudo apt-get -y install cuda
	rm cuda-repo-ubuntu1804-11-4-local_11.4.0-470.42.01-1_amd64.deb
	echo -e "\e[0;32m ========== CUDA Toolkit & Dependencies install completed =========== \e[0m"
else
	echo -e "\e[0;32m Existing CUDA Toolkit & Dependencies detected!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========== continue Installing other(s) dependencies =========== \e[0m"
echo ${SKIPS}
DIST=$(. /etc/os-release && echo ${VERSION_CODENAME-stretch})
if [ "${DIST}" == "focal" ]; then
	sudo python3 -m pip install networkx defusedxml progress numpy google protobuf
	sudo python3 -m pip install requests --upgrade
	sudo chmod a+r /usr/lib/x86_64-linux-gnu/libcuda*
else
	sudo apt-get install -y python-networkx python-defusedxml python-progress python-google-apputils python-protobuf python-numpy python-test-generator \
	python-onnx python-tensorflow
	sudo python3 -m pip install requests --upgrade
	sudo chmod a+r /usr/lib/x86_64-linux-gnu/libcuda*
fi

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer Caffe Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh caffe

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer ONNX Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh onnx

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer TensorFlow Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh tf

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer TensorFlow v2 Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh tf2

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer Keras Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh kaldi

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing OpenVino Model Optimizer MXNET Dependencies on system =========== \e[0m"
echo ${SKIPS}
sudo bash -E /opt/intel/openvino_2021/deployment_tools/model_optimizer/install_prerequisites/install_prerequisites.sh mxnet

echo -e "\e[0;32m ========== Dependencies install completed =========== \e[0m"
