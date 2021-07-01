#set -eo pipefail

CUR_DIR=`pwd`
SKIPS=" "

sudo python3 -m pip install numpy==1.19.5
sudo python3 -m pip install torch torchvision batchgenerators nnunet pandas
## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/build/data/3d-unet ]; then
    mkdir -p ${CUR_DIR}/build/data/3d-unet/BraTS
    curl -L -O https://www.cbica.upenn.edu/sbia/Spyridon.Bakas/MICCAI_BraTS/2019/MICCAI_BraTS_2019_Data_Training.zip
    unzip MICCAI_BraTS_2019_Data_Training.zip -d ${CUR_DIR}/build/data/3d-unet/BraTS
    rm MICCAI_BraTS_2019_Data_Training.zip
echo -e "\e[0;32m 3d-unet datasets downloaded and extracted complete!!\e[0m"
else
    echo -e "\e[0;32m 3d-unet datasets detected!!\e[0m"
fi
echo ${SKIPS}

## Create 3D-unet imagenet calibtration text file
if [ ! -f ${CUR_DIR}/build/data/calibration/brats_cal_images_list.txt ]; then
    mkdir -p ${CUR_DIR}/build/data/calibration/
    cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/brats_cal_images_list.txt ${CUR_DIR}/build/data/calibration/
    echo -e "\e[0;32m Copied 3d-unet imagenet calibration file!!\e[0m"
else
    echo -e "\e[0;32m Existing 3d-unet calibration file detected!!\e[0m"
fi
echo ${SKIPS}

## Check 3d-unet model folder..
if [ ! -d ${CUR_DIR}/build/model/3d-unet ]; then
    mkdir -p ${CUR_DIR}/build/model/3d-unet
    #cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/model/* ${CUR_DIR}/models/3d-unet/
    wget https://ubit-artifactory-sh.intel.com/artifactory/esc-local/utils/3d-unet_model.zip
    unzip 3d-unet_model.zip -d ${CUR_DIR}/build/model/3d-unet/
    rm 3d-unet_model.zip 
    echo -e "\e[0;32m Created 3d-unet model folder!!\e[0m"
else
    echo -e "\e[0;32m Existing 3d-unet model folder detected!!\e[0m"
fi
echo ${SKIPS}

## Download 3D-Unet Fold file data
if [ ! -f build/result/nnUNet/3d_fullres/Task043_BraTS2019/nnUNetTrainerV2__nnUNetPlansv2.mlperf.1/plans.pkl ]; then
    wget https://zenodo.org/record/3904106/files/fold_1.zip
    unzip fold_1.zip ${CUR_DIR}/build/result/nnUNet/
    echo -e "\e[0;32m Created 3d-unet fold data!!\e[0m"
else
    echo -e "\e[0;32m Existing 3d-unet fold data detected!!\e[0m"
fi
echo ${SKIPS}

## Download 3d-unet model file
if [ ! -f ${CUR_DIR}/build/model/3d-unet/3d-unet_fp32.xml ]; then
    if [ ! -f ${CUR_DIR}/build/model/3d-unet/224_224_160.onnx ]; then
        cd ${CUR_DIR}/build/model/3d-unet
        wget https://zenodo.org/record/3928973/files/224_224_160.onnx
    fi

## Optimize and convert model format file into IR files.
    echo -e "\e[0;34m========== Genereting 3d-unet IR files=============\e[0m"
    python3 ${CUR_DIR}/MLPerf-Intel-openvino/dependencies/openvino-repo/model-optimizer/mo_onnx.py \
        --input_model ${CUR_DIR}/build/model/3d-unet/224_224_160.onnx \
        --output_dir ${CUR_DIR}/build/model/3d-unet \
        --model_name 3d-unet_fp32 
    if [ "$?" -ne "0" ]; then
        echo -e "\e[0;31m [Error]: IR generate failed, please check!!\e[0m"
	exit 1
    else
        echo -e "\e[0;32m 3d-unet model download, optimized and IR files files generated!!\e[0m"
    fi
else
    echo -e "\e[0;32m 3d-unet IR files detected!!\e[0m"
fi

## Prepare calibration file 
if [ ! -f ${CUR_DIR}/datasets/3d-unet/BraTS/brats_cal_images_list.txt ]; then
    cp ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/3d-unet/brats_cal_images_list.txt ${CUR_DIR}/build/data/calibration/
    echo -e "\e[0;32m Copied 3d-unet calibration txt file!!\e[0m"
else
    echo -e "\e[0;32m 3d-unet calibration txt detected!!\e[0m"
fi

echo -e "\e[0;34m========== Reading 3d-unet Patients data =============\e[0m"
python3 Task043_BraTS_2019.py \
    --downloaded_data_dir ${CUR_DIR}/build/data/3d-unet/BraTS/MICCAI_BraTS_2019_Data_Training
if [ "$?" -ne "0" ]; then
    echo -e "\e[0;31m [Error]: 3D-Unet preocess patients data file and please check!!\e[0m"
    exit 1
else
    echo -e "\e[0;32m 3D-Unet patiens data preocess completed!!\e[0m"
fi
echo ${SKIPS}

echo -e "\e[0;34m========== Pre-process 3d-unet data =============\e[0m"
python3 preprocess.py \
    --validation_fold_file ${CUR_DIR}/build/data/calibration/brats_cal_images_list.txt \
    --preprocessed_data_dir ${CUR_DIR}/build/data/calibration
if [ "$?" -ne "0" ]; then
    echo -e "\e[0;31m [Error]: 3D-Unet preocess data failed and please check!!\e[0m"
    exit 1
else
    echo -e "\e[0;32m 3D-Unet preocess data completed!!\e[0m"
fi
echo ${SKIPS}

echo -e "\e[0;34m========== Calibrate 3D-Unet Datasets to INT8 Precision =============\e[0m"
python3 ov_calibrate.py \
    --model ${CUR_DIR}/build/model/3d-unet/3d-unet_fp32.xml \
    --model_name 3d-unet_int8 \
    --preprocessed_data_dir ${CUR_DIR}/build/data/calibration/ \
    --int8_directory ${CUR_DIR}/build/model/calibrated
if [ "$?" -ne "0" ]; then
    echo -e "\e[0;31m [Error]: 3D-Unet Calibration failed and please check!!\e[0m"
    exit 1
else
    echo -e "\e[0;32m 3D-Unet calibration completed!!\e[0m"
fi
else
    echo -e "\e[0;32m 3d-unet IR files detected!!\e[0m"
fi
