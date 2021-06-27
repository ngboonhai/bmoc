#set -eo pipefail
set -x

CUR_DIR=`pwd`
SKIPS=" "

## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/ssd-mobilenet ]; then
    mkdir -p ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val
    wget https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar
    tar xf ILSVRC2012_img_val.tar -C ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val
    rm ${CUR_DIR}/ILSVRC2012_img_val.tar
    echo -e "\e[0;32m ssd-mobilenet datasets downloaded and extracted complete!!\e[0m"
else
    echo -e "\e[0;32m ssd-mobilenet datasets detected!!\e[0m"
fi
echo ${SKIPS}

## Create resnet imagenet validation text file
if [ ! -f ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val/val_map.txt ]; then
    shuf -n 2000 bmoc/cm/mpoc/intel/inference_v1.0/ssd-mobilenet/val_map.txt > ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val/val_map.txt
    cat ${CUR_DIR}/datasets/ssd-mobilenet/dataset-coco-2017-val/val_map.txt | wc -l
    echo -e "\e[0;32m ssd-mobilenet imagenet validation file generated!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-mobilenet validation file detected!!\e[0m"
fi
echo ${SKIPS}

## Check ssd-mobilenet model folder..
if [ ! -d ${CUR_DIR}/models/ssd-mobilenet ]; then
    mkdir -p ${CUR_DIR}/models/ssd-mobilenet
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/ssd-mobilenet/model ${CUR_DIR}/Configs/ssd-mobilenet/
    echo -e "\e[0;32m Created ssd-mobilenet model folder!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-mobilenet model folder detected!!\e[0m"
fi
echo ${SKIPS}

## Download ssd-mobilenet TenrsorFlow model file and optimize the file with OpenVino toolkit
if [ ! -f ${CUR_DIR}/models/ssd-mobilenet/ssd-mobilenet_fp16.xml ]; then
    cd ${CUR_DIR}/models/ssd-mobilenet
    wget https://zenodo.org/record/2535873/files/ssd-mobilenet_v1.pb
    cd ${CUR_DIR}

    echo "========== Genereting ssd-mobilenet IR files============="
## Convert existing model file into FP16
    python3 ${CUR_DIR}/MLPerf-Intel-openvino/dependencies/openvino-repo/model_optimizer/mo_tf.py \
        --input_model ${CUR_DIR}/models/ssd-mobilenet/ssd-mobilenet_v1.pb \
        --data_type FP16 \
        --output_dir ${CUR_DIR}/models/ssd-mobilenet \
        --input_shape [1,224,224,3] \
        --mean_values "[123.68, 116.78, 103.94]" \
        --model_name ssd-mobilenet_fp16 \
        --output softmax_tensor
    echo -e "\e[0;32m ssd-mobilenet model files generated!!\e[0m"
else
    echo -e "\e[0;32m ssd-mobilenet model files detected!!\e[0m"
fi
