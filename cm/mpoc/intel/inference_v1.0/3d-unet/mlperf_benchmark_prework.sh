#set -eo pipefail

CUR_DIR=`pwd`
SKIPS=" "

sudo python3 -m pip install numpy==1.19.5
sudo python3 -m pip install torch torchvision batchgenerators nnunet pandas
## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/3d-unet ]; then
    mkdir -p ${CUR_DIR}/datasets/3d-unet/BraTS
    curl -L -O https://www.cbica.upenn.edu/sbia/Spyridon.Bakas/MICCAI_BraTS/2019/MICCAI_BraTS_2019_Data_Training.zip
    unzip MICCAI_BraTS_2019_Data_Training.zip -d ${CUR_DIR}/datasets/3d-unet/BraTS
    rm MICCAI_BraTS_2019_Data_Training.zip
echo -e "\e[0;32m 3d-unet datasets downloaded and extracted complete!!\e[0m"
else
    echo -e "\e[0;32m 3d-unet datasets detected!!\e[0m"
fi
echo ${SKIPS}

## Create resnet imagenet validation text file
#if [ ! -f ${CUR_DIR}/datasets/3d-unet/dataset-coco-2017-val/val_map.txt ]; then
#    shuf -n 2000 bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/val_map.txt > ${CUR_DIR}/datasets/3d-unet/dataset-coco-2017-val/val_map.txt
#    cat ${CUR_DIR}/datasets/3d-unet/dataset-coco-2017-val/val_map.txt | wc -l
#    echo -e "\e[0;32m 3d-unet imagenet validation file generated!!\e[0m"
#else
#    echo -e "\e[0;32m Existing 3d-unet validation file detected!!\e[0m"
#fi
#echo ${SKIPS}

## Check 3d-unet model folder..
if [ ! -d ${CUR_DIR}/models/3d-unet ]; then
    mkdir -p ${CUR_DIR}/models/3d-unet
    #cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/model/* ${CUR_DIR}/models/3d-unet/
    wget https://ubit-artifactory-sh.intel.com/artifactory/esc-local/utils/3d-unet_model.zip
    unzip 3d-unet_model.zip -d ${CUR_DIR}/models/3d-unet
    echo -e "\e[0;32m Created 3d-unet model folder!!\e[0m"
else
    echo -e "\e[0;32m Existing 3d-unet model folder detected!!\e[0m"
fi
echo ${SKIPS}

## Download 3d-unet model file
if [ ! -f ${CUR_DIR}/models/3d-unet/3d-unet_fp32.xml ]; then
    if [ ! -f ${CUR_DIR}/models/3d-unet/224_224_160.onnx ]; then
        cd ${CUR_DIR}/models/3d-unet
        wget https://zenodo.org/record/3928973/files/224_224_160.onnx
        cd ${CUR_DIR}
    fi

    echo -e "\e[0;34m========== Genereting 3d-unet IR files=============\e[0m"
    ## Convert existing model file into FP16
    python3 ${CUR_DIR}/MLPerf-Intel-openvino/dependencies/openvino-repo/model-optimizer/mo_onnx.py \
        --input_model ${CUR_DIR}/models/3d-unet/224_224_160.onnx \
        --output_dir ${CUR_DIR}/models/3d-unet \
        --model_name 3d-unet_fp32 
    if [ "$?" -ne "0" ]; then
        echo -e "\e[0;31m [Error]: IR generate failed, please check!!\e[0m"
    else
        echo -e "\e[0;32m 3d-unet model download, optimized and IR files files generated!!\e[0m"
    fi
    
    if [ ! -f ${CUR_DIR}/datasets/3d-unet/BraTS/brats_cal_images_list.txt ]; then
        cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/brats_cal_images_list.txt ${CUR_DIR}/datasets/3d-unet/BraTS
        echo -e "\e[0;32m Copied 3d-unet calibration txt file!!\e[0m"
    else
        echo -e "\e[0;32m 3d-unet calibration txt detected!!\e[0m"
    fi
    
    if [ ! -f ${CUR_DIR}/preprocess.py ]; then
        cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/preprocess.py ${CUR_DIR}/preprocess.py
        echo -e "\e[0;32m Copied 3d-unet preprocess python script file!!\e[0m"
    else
        echo -e "\e[0;32m 3d-unet preprocess python file detected!!\e[0m"
    fi

    echo -e "\e[0;34m========== 3D-Unet Preprocess and Calibrate Datasets =============\e[0m"
    python preprocess.py \
        --validation_fold_file ${CUR_DIR}/datasets/3d-unet/BraTS/brats_cal_images_list.txt \
        --preprocessed_data_dir ${CUR_DIR}/datasets/3d-unet/BraTS
    if [ "$?" -ne "0" ]; then
        echo -e "\e[0;31m [Error]: 3D-Unet preocess data faile and please check!!\e[0m"
    else
        echo -e "\e[0;32m 3D-Unet preocess data completed!!\e[0m"
    fi
        
    python ov_calibrate.py \
        --model build/model/3d_unet_model.xml \
        --model_name 3d_unet_model \
        --preprocessed_data_dir ${CUR_DIR}/datasets/3d-unet/BraTS \
        --int8_directory ${CUR_DIR}/models/calibrated
    if [ "$?" -ne "0" ]; then
        echo -e "\e[0;31m [Error]: 3D-Unet Calibration failed and please check!!\e[0m"
    else
        echo -e "\e[0;32m 3D-Unet calibration completed!!\e[0m"
    fi
else
    echo -e "\e[0;32m 3d-unet IR files detected!!\e[0m"
fi
