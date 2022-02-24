MODEL=$1
DEVICE=$2
BATCH_SIZE=$3

#if [ "${DEVICE}" == "CPU" ]; then
#	file_arg=cpu
#elif [ "${DEVICE}" == "GPU" ]; then
#	file_arg=gpu
#elif [ "${DEVICE}" == "MULTI:CPU,GPU" ]; then
#	file_arg=cpugpu
#fi

#logfile="${MODEL}_${file_arg}.log"
IFS=","
for BATCH_VALUE in ${BATCH_SIZE}
do
	if [ "${MODEL}" == "resnet50" ]; then
		/opt/intel/openvino_2021/deployment_toolsark_tool/benchmark_app.py -m /home/iotg/public/r/tools/benchmesnet-50-tf/FP16-INT8/resnet-50-tf.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi

	if [ "${MODEL}" == "ssd-resnet34" ]; then
		/opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m /home/iotg/public/ssd-resnet34-1200-onnx/FP16/ssd-resnet34-1200-onnx.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi

	if [ "${MODEL}" == "ssd-mobilenet" ]; then
		/opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m /home/iotg/public/ssd_mobilenet_v1_coco/FP16-INT8/ssd_mobilenet_v1_coco.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi

	if [ "${MODEL}" == "ssd300" ]; then
		/opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m /home/iotg/public/ssd300/FP16/ssd300.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi

	if [ "${MODEL}" == "yolo-v4" ]; then
		/opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m /home/iotg/public/yolo-v4-tf/FP16/yolo-v4-tf.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi

	if [ "${MODEL}" == "yolo-v3-tiny" ]; then
		/opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m /home/iotg/public/yolo-v3-tiny-tf/FP16/yolo-v3-tiny-tf.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi

	if [ "${MODEL}" == "yolo-v3" ]; then
		/opt/intel/openvino_2021/deployment_tools/tools/benchmark_tool/benchmark_app.py -m /home/iotg/public/yolo-v3-tf/FP16/yolo-v3-tf.xml -d "${DEVICE}" -i /home/iotg/datasets/input_images -b ${BATCH_VALUE} -nthreads $(nproc)
	fi
done
