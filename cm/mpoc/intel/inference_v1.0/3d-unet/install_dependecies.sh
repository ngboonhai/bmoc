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

SKIPS=" "
DASHES="================================================"

echo ${SKIPS}
echo -e "\e[0;34m ========= Check and installing workload dependencis ========= \e[0m"
echo ${SKIPS}

sudo apt update
sudo apt-get install -y libglib2.0-dev libtbb-dev python3-dev python3-pip python3-venv unzip python3.8-venv libssl-dev libgtk-3-dev

python3 -m venv 3d-unet
source 3d-unet/bin/activate
python3 -m pip install --upgrade pip

CUR_DIR=`pwd`
BUILD_DIRECTORY=${CUR_DIR}

echo -e "\e[0;34m ========== Installing CMAKE >= 3.17.3 dependencies =========== \e[0m"
cmake_ver=`cmake --version | head -1 | awk '{print $3}'`
if [ -z $cmake_ver ] || [ ! "${cmake_ver}" == "3.17.3" ]; then
	wget https://github.com/Kitware/CMake/releases/download/v3.17.3/cmake-3.17.3.tar.gz
 	tar -xzf cmake-3.17.3.tar.gz
 	rm cmake-3.17.3.tar.gz
 	cd cmake-3.17.3
 	./bootstrap --prefix=/usr -- -DCMAKE_BUILD_TYPE:STRING=Release
 	make -j8
 	sudo make install
	rm -rf cmake-3.17*	
	cmake_version=`cmake --version | head -1 | awk '{print $3}'`
	echo -e "\e[0;32m Cmake ${cmake_version} installed!!\e[0m"
else
	echo -e "\e[0;32m Cmake >=3.17.3 installed!!\e[0m"
fi

echo ${SKIPS}
echo -e "\e[0;34m ========== Installing Full packages of OpenVino Toolkit =========== \e[0m"
echo ${SKIPS}
if [ ! -d /opt/intel/openvino_2021 ]; then
	wget https://ubit-artifactory-sh.intel.com/artifactory/esc-local/utils/openvino/2021.3/l_openvino_toolkit_p_2021.3.394.tgz
	tar xvf l_openvino_toolkit_p_2021.3.394.tgz
	cat ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/silent.cfg > l_openvino_toolkit_p_2021.3.394/silent.cfg
	cd l_openvino_toolkit_p_2021.3.394
	sudo ./install.sh -s silent.cfg
	cd ${CUR_DIR}
	rm -rf l_openvino_toolkit_p_2021.3.394*
	sudo ln -sf /opt/intel/openvino_2021.3.394 /opt/intel/openvino_2021
	source /opt/intel/openvino_2021/bin/setupvars.sh
	echo -e "\e[0;32m Openvino Toolkit has installed!!\e[0m"
else
	echo -e "\e[0;32m Openvino Toolkit installed!!\e[0m"
fi

echo -e "\e[0;34m ========== continue Installing other(s) dependencies =========== \e[0m"
DIST=$(. /etc/os-release && echo ${VERSION_CODENAME-stretch})
if [ "${DIST}" == "focal" ]; then
        python3 -m pip install defusedxml numpy==1.18.0 test-generator==0.1.1 tensorflow==2.3.3 onnx==1.7.0
	python3 -m pip install addict==2.4.0 networkx==2.5 tqdm==4.54.1 pandas==1.1.5 Cython==0.29.23
	python3 -m pip install opencv-python==4.5.2.54 openvino==2021.4.0 openvino-dev==2021.4.0
	python3 -m pip install torch torchvision batchgenerators nnunet texttable progress
else
	CHECK_LIBRAW=`whereis libraw`
	if [ ! -z ${CHECK_LIBRAW} ]; then
		cd /tmp
		git clone https://github.com/LibRaw/LibRaw.git libraw
		git clone https://github.com/LibRaw/LibRaw-cmake.git libraw-cmake
		cd libraw
		git checkout 0.20.0
		cp -R ../libraw-cmake/* .
		cmake .
		sudo make install
		rm -rf /tmp/libraw*
		cd ${CUR_DIR}
	fi
	python3 -m pip install --upgrade setuptools
        python3 -m pip install defusedxml numpy==1.16.4 test-generator==0.1.1 onnx==1.7.0 tensorflow==2.0.0a0
	python3 -m pip install addict networkx tqdm pandas Cython scikit-build
	python3 -m pip install openvino
	python3 -m pip install opencv-python openvino-dev
	python3 -m pip install torch torchvision batchgenerators nnunet texttable progress
fi

MLPERF_DIR=${BUILD_DIRECTORY}/MLPerf-Intel-openvino
DEPS_DIR=${MLPERF_DIR}/dependencies

#====================================================================
#   Build OpenVINO library (If not using publicly available openvino)
#====================================================================
OPENVINO_DIR=${DEPS_DIR}/openvino-repo
echo ${SKIPS}
echo -e "\e[0;34m ========== Building OpenVINO Libraries =========== \e[0m"
echo ${SKIPS}
if [ ! -d ${OPENVINO_DIR} ]; then
	git clone https://github.com/openvinotoolkit/openvino.git ${OPENVINO_DIR}
	cd ${OPENVINO_DIR}
	git checkout releases/2021/2
	git submodule update --init --recursive
	mkdir build && cd build
	cmake -DENABLE_VPU=OFF \
		  -DTHREADING=OMP \
		  -DENABLE_GNA=OFF \
		  -DENABLE_DLIA=OFF \
		  -DENABLE_TESTS=OFF \
		  -DENABLE_VALIDATION_SET=OFF \
		  -DNGRAPH_ONNX_IMPORT_ENABLE=OFF \
		  -DNGRAPH_DEPRECATED_ENABLE=FALSE \
		  -DPYTHON_EXECUTABLE=`which python3` \
		  ..

	TEMPCV_DIR=${OPENVINO_DIR}/inference-engine/temp/opencv_4*
	OPENCV_DIRS=$(ls -d -1 ${TEMPCV_DIR} )
	export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OPENCV_DIRS[0]}/opencv/lib

	make -j$(nproc)
else
	TEMPCV_DIR=${OPENVINO_DIR}/inference-engine/temp/opencv_4*
	OPENCV_DIRS=$(ls -d -1 ${TEMPCV_DIR} )
	echo -e "\e[0;32m OpenVinon Toolkit installed!!\e[0m"
fi

#=============================================================
#   Build Gflags
#=============================================================
GFLAGS_DIR=${DEPS_DIR}/gflags
echo ${SKIPS}
echo -e "\e[0;34m ============ Building Gflags =========== \e[0m"
echo ${SKIPS}
if [ ! -d ${GFLAGS_DIR} ]; then
	git clone https://github.com/gflags/gflags.git ${GFLAGS_DIR}
	cd ${GFLAGS_DIR}
	mkdir gflags-build && cd gflags-build
	cmake .. && make 
else
	echo -e "\e[0;32m GFLAGS Tools installed!!\e[0m"
fi

#=============================================================
#   Build boost
#=============================================================
BOOST_DIR=${DEPS_DIR}/boost
echo ${SKIPS}
echo -e "\e[0;34m ========= Building Boost v1.72.0 ========== \e[0m"
echo ${SKIPS}
if [ ! -d ${BOOST_DIR} ]; then
	mkdir ${BOOST_DIR}
	cd ${BOOST_DIR}
	wget https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.gz
	tar -xzf boost_1_72_0.tar.gz
	cd boost_1_72_0
	./bootstrap.sh --with-libraries=filesystem 
	./b2 --with-filesystem
else
	echo -e "\e[0;32m BOOST Tools installed!!\e[0m"
fi

#===============================================================
#   Build loadgen
#===============================================================
MLPERF_INFERENCE_REPO=${DEPS_DIR}/mlperf-inference
echo ${SKIPS}
echo -e "\e[0;34m =========== Check MLPerf Load Generator ========== \e[0m"
if [ ! -f ${CUR_DIR}/bin/3d_unet_ov_mlperf ]; then
	echo ${SKIPS}
	echo -e "\e[0;34m =========== Building MLPerf Load Generator ========== \e[0m"
	echo ${SKIPS}

	python3 -m pip install absl-py numpy pybind11
	if [ ! -d ${MLPERF_INFERENCE_REPO} ]; then
		git clone --recurse-submodules https://github.com/mlcommons/inference.git ${MLPERF_INFERENCE_REPO}
		cd ${MLPERF_INFERENCE_REPO}/loadgen
		git checkout r1.0
		git submodule update --init --recursive
		mkdir build && cd build
		cmake -DPYTHON_EXECUTABLE=`which python3` ..
		make
		cp libmlperf_loadgen.a ../
		echo -e "\e[0;32m MLPerf Load Generator installed!!\e[0m"
	else
		echo -e "\e[0;32m MLPerf Load Generator detected!!\e[0m"
	fi
	cd ${MLPERF_DIR}

# =============================================================
#        Build ov_mlperf
#==============================================================

	echo ${SKIPS}
	echo -e "\e[0;34m ========== Building ov_mlperf binary file =========== \e[0m"
	echo ${SKIPS}

	git clone https://github.com/mlcommons/inference_results_v1.0.git 
	cp -r inference_results_v1.0/closed/Intel/code/3d-unet-99.9/openvino ${CUR_DIR}
	SOURCE_DIR=${CUR_DIR}/openvino
	cd ${SOURCE_DIR}

	if [ -d build ]; then
		rm -r build
	fi

	mkdir build && cd build
	. /opt/intel/openvino_2021/bin/setupvars.sh
	cmake -DInferenceEngine_DIR=/opt/intel/openvino_2021/deployment_tools/inference_engine/share \
	       -DOpenCV_DIR=${OPENCV_DIRS[0]}/opencv/cmake/ \
	       -DLOADGEN_DIR=${MLPERF_INFERENCE_REPO}/loadgen \
	       -DLOADGEN_LIB_DIR=${MLPERF_INFERENCE_REPO}/loadgen/build \
               -DBOOST_INCLUDE_DIRS=${BOOST_DIR}/boost_1_72_0 \
               -DBOOST_FILESYSTEM_LIB=${BOOST_DIR}/boost_1_72_0/stage/lib/libboost_filesystem.so \
               -DCMAKE_BUILD_TYPE=Release \
               -Dgflags_DIR=${GFLAGS_DIR}/gflags-build/ \
          ..
	make
	if [ "$?" -ne "0" ]; then
        	echo -e "\e[0;31m [Error]: ov_mlperf not built. Please check logs on screen!!  \e[0m"
		exit 1
    	else
        	echo -e "\e[1;32m ov_mlperf built and copy to ${CUR_DIR}/bin/3d_unet_ov_mlperf  \e[0m"
    	fi
	echo ${SKIPS}
	echo ${DASHES}

    mkdir -p ${CUR_DIR}/bin
    cp ${SOURCE_DIR}/bin/intel64/Release/ov_mlperf ${CUR_DIR}/bin/3d_unet_ov_mlperf
    
    ## Print and notify where the MLperf Library location
    echo ${SKIPS}
    echo " * * * Important directories * * *"
    echo -e "\e[1;32m OPENVINO_LIBRARIES=${OPENVINO_DIR}/bin/intel64/Release/lib    \e[0m"
    echo -e "\e[1;32m OPENCV_LIBRARIES=${OPENCV_DIRS[0]}/opencv/lib                 \e[0m"
    echo -e "\e[1;32m OMP_LIBRARY=${OPENVINO_DIR}/inference-engine/temp/omp/lib     \e[0m"
    echo -e "\e[1;32m BOOST_LIBRARIES=${BOOST_DIR}/boost_1_72_0/stage/lib           \e[0m"
    echo -e "\e[1;32m GFLAGS_LIBRARIES=${GFLAGS_DIR}/gflags-build/lib               \e[0m"
    if [ ! -f ${CUR_DIR}/setup_envs.sh ]; then
		## Setup mlperf environment variable
		echo "#!/bin/bash" >  ${CUR_DIR}/setup_envs.sh
		echo ${SKIPS} >> ${CUR_DIR}/setup_envs.sh
		echo "OPENVINO_LIBRARIES=${OPENVINO_DIR}/bin/intel64/Release/lib" >> ${CUR_DIR}/setup_envs.sh
		echo "OPENCV_LIBRARIES=${OPENCV_DIRS[0]}/opencv/lib" >> ${CUR_DIR}/setup_envs.sh
		echo "OMP_LIBRARY=${OPENVINO_DIR}/inference-engine/temp/omp/lib" >> ${CUR_DIR}/setup_envs.sh
		echo "BOOST_LIBRARIES=${BOOST_DIR}/boost_1_72_0/stage/lib" >> ${CUR_DIR}/setup_envs.sh
		echo "GFLAGS_LIBRARIES=${GFLAGS_DIR}/gflags-build/lib" >> ${CUR_DIR}/setup_envs.sh
		echo ${SKIPS} >> ${CUR_DIR}/setup_envs.sh
		echo 'export LD_LIBRARY_PATH=${OPENVINO_LIBRARIES}:${OMP_LIBRARY}:${OPENCV_LIBRARIES}:${BOOST_LIBRARIES}:${GFLAGS_LIBRARIES}' >> ${CUR_DIR}/setup_envs.sh
		echo "export OV_MLPERF_BIN=${CUR_DIR}/bin/3d_unet_ov_mlperf" >> ${CUR_DIR}/setup_envs.sh
		echo "export DATA_DIR=${CUR_DIR}/datasets"  >> ${CUR_DIR}/setup_envs.sh
		echo "export MODELS_DIR=${CUR_DIR}/models"  >> ${CUR_DIR}/setup_envs.sh
		echo "export CONFIGS_DIR=${CUR_DIR}/Configs" >> ${CUR_DIR}/setup_envs.sh
	fi
else
        echo -e "\e[0;32m Existing MLPerf Load Generator and ov_mlperf binary detected. \e[0m"
fi

## copy preprocess and other python script needed.
if [ ! -f ${CUR_DIR}/preprocess.py ]; then
    cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/preprocess.py ${CUR_DIR}/preprocess.py
    cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/ov_calibrate.py ${CUR_DIR}/ov_calibrate.py
    cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/Task043_BraTS_2019.py ${CUR_DIR}/Task043_BraTS_2019.py
    sudo cp ${MLPERF_INFERENCE_REPO}/vision/medical_imaging/3d-unet/brats_QSL.py /usr/local/lib/python3.8/dist-packages/
    echo -e "\e[0;32m Copied 3d-unet preprocess python script file!!\e[0m"
else
    echo -e "\e[0;32m 3d-unet preprocess python file detected!!\e[0m"
fi

if [ -d ${SOURCE_DIR} ]; then
	rm -rf ${SOURCE_DIR}
fi

if [ -d ${MLPERF_DIR}/inference_results_v1.0 ]; then
	rm -rf ${MLPERF_DIR}/inference_results_v1.0
fi
echo ${DASHES}
