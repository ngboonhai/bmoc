## Create Container images with OpenVino Toolkit install on top of existing Container
- cd \<this-repp>/cm/mpoc/Intel/openvino
- docker build -t <new_image_name> --build-arg IMAGE=<existing_image_name> -f <dockerfile_name> . 

## Download OpenVino Model Optimizer (do if not exist)
- cd /opt/intel/openvino_<version>/ \
- git clone https://github.com/openvinotoolkit/openvino.git \
- cp -r openvino/model-optimzer /opt/intel/openvino_\<version>/deplotment_tools/
- Install other re-requisites components needed to OpenVino Model Optimizer utility, run <model-optimizer-repo>/install_prerequisites/install_prerequisites.sh
