# Environment dependencies: 
## GCC 7.5
apt-get install -y gcc-7-base

## CMake 3.17.2
apt-get install build-essential libssl-dev \
cd /tmp && wget https://github.com/Kitware/CMake/releases/download/v3.17.2/cmake-3.17.2.tar.gz \
tar -zxvf cmake-3.20.0.tar.gz && cd cmake-3.17.2 \
./bootstrap && make && make install && cmake --version

## Python 3.6
add-apt-repository ppa:deadsnakes/ppa \
apt-get update \
apt-get install python3.6 -y

## OpenVino Dependencies
apt install -y g++ clang make ninja-build wget unzip git \
cd /tmp \
git clone https://github.com/opencv/opencv.git \
git -C opencv checkout master \
cd opencv \
mkdir -p build && cd build \
cmake ../../opencv \
make -j4 \
make install \

git clone https://github.com/gflags/gflags.git \
cd gflags \
mkdir build && cd build \
cmake .. \
make \

cd /tmp \
wget https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.gz \
tar -xzvf boost_1_72_0.tar.gz \
cd boost_1_72_0 \
./bootstrap --with-libraries=filesystem && ./b2 --with-filesystem

mkdir -p mlperf \
git clone https://github.com/mlperf/inference_results_v0.7.git \
cd inference_results_v0.7/closed/intel/ \

##  Download APT Key for OpenVino packages
cd /tmp \
wget https://apt.repos.intel.com/openvino/2021/GPG-PUB-KEY-INTEL-OPENVINO-2021 \
apt-key add /tmp/GPG-PUB-KEY-INTEL-OPENVINO-2021 \
apt-key list \
echo "deb https://apt.repos.intel.com/openvino/2021 all main" | sudo tee /etc/apt/sources.list.d/intel-openvino-2021.list \
apt update \
sudo apt install intel-openvino-runtime-ubuntu20-2021.1.105

## Building and Install MLPerf Load Generator - mlperf_loadgen
apt-get install libglib2.0-dev python-pip python3-pip \
pip install absl-py numpy
git clone https://github.com/mlperf/inference.git
cd inference && git checkout r1.0
git log -1
git submodule sync && git submodule update --init --recursive
cd loadgen && CFLAGS="-std=c++14" python setup.py install

## Download OpenVino Optimizer models to /opt/intel/openvino_<version>/ directory
git clone https://github.com/openvinotoolkit/openvino \
cp -r openvino/model-optimzer /opt/intel/openvino_<version>
