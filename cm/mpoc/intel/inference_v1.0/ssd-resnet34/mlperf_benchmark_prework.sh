#set -eo pipefail
set -x

CUR_DIR=`pwd`

## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/ssd-resnet34 ]; then
    mkdir -p ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val
    wget http://images.cocodataset.org/zips/val2017.zip
	wget http://images.cocodataset.org/annotations/annotations_trainval2017.zip
    unzip val2017.zip -d ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val
	unzip annotations_trainval2017.zip -d ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val
    rm ${CUR_DIR}/ILSVRC2012_img_val.tar
else
	echo -e "\e[1;32m COCO val2017 datatsets available in system          \e[0m"
fi

## Create resnet imagenet validation text file
shuf -n 2000 bmoc/cm/mpoc/intel/inference_v1.0/ssd-resnet34/val_map.txt > ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val/val2017/val_map.txt
cat ${CUR_DIR}/datasets/ssd-resnet34/dataset-coco-2017-val/val2017/val_map.txt | wc -l


## Download ssd-resnet34 model file
if [ ! -f ${CUR_DIR}/models/ssd-resnet34/resnet34-ssd1200.onnx ]; then
	mkdir ${CUR_DIR}/models/ssd-resnet34
	cd ${CUR_DIR}/models/ssd-resnet34
	wget https://zenodo.org/record/3228411/files/resnet34-ssd1200.onnx
	cd ${CUR_DIR}
fi

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
