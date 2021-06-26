#set -eo pipefail
set -x

CUR_DIR=`pwd`

## Download dataset from Image-net Org.
if [ ! -d ${CUR_DIR}/datasets/resnet50 ]; then
    mkdir -p ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val
    wget https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar
    tar xf ILSVRC2012_img_val.tar -C ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val
    rm ${CUR_DIR}/ILSVRC2012_img_val.tar
fi

## Create resnet imagenet validation text file
shuf -n 2000 bmoc/cm/mpoc/intel/inference_v1.0/resnet50/val_map.txt > ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val/val_map.txt
cat ${CUR_DIR}/datasets/resnet50/dataset-imagenet-ilsvrc2012-val/val_map.txt | wc -l


## Download resnet50 model file
if [ ! -f ${CUR_DIR}/models/resnet50/resnet50_v1.pb ]; then
	mkdir ${CUR_DIR}/models/resnet50
	cd ${CUR_DIR}/models/resnet50
	wget https://zenodo.org/record/2535873/files/resnet50_v1.pb
	cd ${CUR_DIR}
fi

## Convert existing model file into FP16
python3 ${CUR_DIR}/MLPerf-Intel-openvino/dependencies/openvino-repo/model_optimizer/mo_tf.py \
  	--input_model ${CUR_DIR}/models/resnet50/resnet50_v1.pb \
	--data_type FP16 \
	--output_dir ${CUR_DIR}/models/resnet50 \
	--input_shape [1,224,224,3] \
	--mean_values "[123.68, 116.78, 103.94]" \
	--model_name resnet50_fp16 \
	--output softmax_tensor