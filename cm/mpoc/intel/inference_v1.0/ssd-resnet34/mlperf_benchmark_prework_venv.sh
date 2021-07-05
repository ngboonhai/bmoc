#set -eo pipefail

python3 -m venv ssd-resnet34
source ssd-resnet34/bin/activate

CUR_DIR=`pwd`
SKIPS=" "

## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/ssd-resnet34 ]; then
    mkdir -p ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val
    wget http://images.cocodataset.org/zips/val2017.zip
	wget http://images.cocodataset.org/annotations/annotations_trainval2017.zip
    unzip val2017.zip -d ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val
	unzip annotations_trainval2017.zip -d ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val
    rm ${CUR_DIR}/val2017.zip ${CUR_DIR}/annotations_trainval2017.zip
echo -e "\e[0;32m ssd-resnet34 datasets downloaded and extracted complete!!\e[0m"
else
    echo -e "\e[0;32m ssd-resnet34 datasets detected!!\e[0m"
fi
echo ${SKIPS}

## Create resnet imagenet validation text file
if [ ! -f ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val/val_map.txt ]; then
    shuf -n 2000 bmoc/cm/mpoc/intel/inference_v1.0/ssd-resnet34/val_map.txt > ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val/val_map.txt
    cat ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val/val_map.txt | wc -l
    echo -e "\e[0;32m ssd-resnet34 imagenet validation file generated!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-resnet34 validation file detected!!\e[0m"
fi
echo ${SKIPS}

## Check ssd-resnet34 model folder..
if [ ! -d ${CUR_DIR}/models/ssd-resnet34 ]; then
    mkdir -p ${CUR_DIR}/models/ssd-resnet34
    cp -r ${CUR_DIR}/bmoc/cm/mpoc/intel/inference_v1.0/ssd-resnet34/model/* ${CUR_DIR}/models/ssd-resnet34/
    echo -e "\e[0;32m Created ssd-resnet34 model folder!!\e[0m"
else
    echo -e "\e[0;32m Existing ssd-resnet34 model folder detected!!\e[0m"
fi
echo ${SKIPS}

## Download ssd-resnet34 model file
if [ ! -f ${CUR_DIR}/models/ssd-resnet34/ssd-resnet34_fp16.xml ]; then
	if [ ! -f ${CUR_DIR}/models/ssd-resnet34/resnet34-ssd1200.onnx ]; then
		cd ${CUR_DIR}/models/ssd-resnet34
		wget https://zenodo.org/record/3228411/files/resnet34-ssd1200.onnx
		cd ${CUR_DIR}
	fi

    echo "========== Genereting ssd-resnet34 IR files============="
    ## Convert existing model file into FP16
    python3 ${CUR_DIR}/MLPerf-Intel-openvino/dependencies/openvino-repo/model-optimizer/mo.py \
    	--input_model ${CUR_DIR}/models/ssd-resnet34/resnet34-ssd1200.onnx \
	--data_type FP16 \
	--output_dir ${CUR_DIR}/models/ssd-resnet34 \
	--model_name ssd-resnet34_fp16 \
	--input image \
	--mean_values [123.675,116.28,103.53] \
	--scale_values [58.395,57.12,57.375] \
	--input_shape "[1,3,1200,1200]" \
	--keep_shape_ops
    if [ "$?" -ne "0" ]; then
        echo -e "\e[0;31m [Error]: IR generate failed, please check!!\e[0m"
    else
        echo -e "\e[0;32m ssd-resnet34 model download, optimized and IR files files generated!!\e[0m"
    fi
else
    echo -e "\e[0;32m ssd-resnet34 IR files detected!!\e[0m"
fi
