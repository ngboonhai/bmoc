# Environment dependencies install require
- git clone https://github.com/mlcommons/inference_results_v1.0.git
- Change Boots Tools URL to "https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.gz", because the outdated URL given inside the file.
- Please run "build-ovmlperf.sh" on directory <repo>/closed/Intel/code/resnet50/openvino
- pip3 install networkx tensorflow requests numpy
  
## Download OpenVino Model Optimizer to /opt/intel/openvino_<version>/ directory
- git clone https://github.com/openvinotoolkit/openvino.git \
- cp -r openvino/model-optimzer /opt/intel/openvino_\<version>/deplotment_tools/
- Install other re-requisites components needed to OpenVino Model Optimizer utility, run <model-optimizer-repo>/install_prerequisites/install_prerequisites.sh
  
