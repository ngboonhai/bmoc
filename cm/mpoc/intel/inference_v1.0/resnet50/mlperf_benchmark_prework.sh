#set -eo pipefail
set -x

CUR_DIR=`pwd`
SKIPS=" "

## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/resnet50 ]; then
    mkdir -p ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val
    wget https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar
    tar xf ILSVRC2012_img_val.tar -C ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val
    rm ${CUR_DIR}/ILSVRC2012_img_val.tar
    echo -e "\e[0;32m Resnet50 datasets downloaded and extracted complete!!\e[0m"
else
    echo -e "\e[0;32m Resnet50 datasets detected!!\e[0m"
fi
echo ${SKIPS}

## Create resnet imagenet validation text file
if [ ! -f ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val/val_map.txt ]; then
    shuf -n 2000 bmoc/cm/mpoc/intel/inference_v1.0/resnet50/val_map.txt > ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val/val_map.txt
    cat ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val/val_map.txt | wc -l
    echo -e "\e[0;32m Resnet50 imagenet validation file generated!!\e[0m"
else
    echo -e "\e[0;32m Existing Resnet50 validation file detected!!\e[0m"
fi
echo ${SKIPS}

## Check Resnet50 model folder..
if [ ! -d ${CUR_DIR}/models/resnet50 ]; then
    mkdir -p ${CUR_DIR}/models/resnet50
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/resnet50/model ${CUR_DIR}/Configs/resnet50/
    echo -e "\e[0;32m Created Resnet50 model folder!!\e[0m"
else
    echo -e "\e[0;32m Existing Resnet50 model folder detected!!\e[0m"
fi
echo ${SKIPS}

## Download resnet50 TenrsorFlow model file and optimize the file with OpenVino toolkit
if [ ! -f ${CUR_DIR}/models/resnet50/resnet50_fp16.xml ]; then
    if [ ! -f ${CUR_DIR}/models/resnet50/resnet50_v1.pb ]; then
        cd ${CUR_DIR}/models/resnet50
        wget https://zenodo.org/record/2535873/files/resnet50_v1.pb
        cd ${CUR_DIR}
    fi

    echo "========== Genereting Resnet50 IR files============="
## Convert existing model file into FP16
    python3 ${CUR_DIR}/MLPerf-Intel-openvino/dependencies/openvino-repo/model-optimizer/mo_tf.py \
        --input_model ${CUR_DIR}/models/resnet50/resnet50_v1.pb \
        --data_type FP16 \
        --output_dir ${CUR_DIR}/models/resnet50 \
        --input_shape [1,224,224,3] \
        --mean_values "[123.68, 116.78, 103.94]" \
        --model_name resnet50_fp16 \
        --output softmax_tensor
        
    echo -e "\e[0;32m Download Resnet50 model, optimize and IR generated!!\e[0m"
else
    echo -e "\e[0;32m Resnet50 IR files detected!!\e[0m"
fi
