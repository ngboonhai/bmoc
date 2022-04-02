#! /bin/bash

declare Total_throughput=0
CODEC1="h264,h265,vp8,vp9"
video_src="Netflix_Aerial_4096x2160_60fps_10bit_420.y4m"
VIDEO_CONVERTOR="nvvideoconvert"
SYSTEM_ARCH=`uname -p`
log_filename="encode_gst"
rm *$log_filename*.log

## Check system Arch version - x86 or aarch64
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        SUDO="sudo"
        VIDEO_CONVERTOR="nvvidconv"
fi


for code1 in ${CODEC1//,/ };
do
	if [ "$code1" == "h264" ]; then
		encode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} ! videoparse width=4096 height=2160 format=nv12 framerate=60/1 ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2${code1}enc ! queue ! perf ! fakesink -e"
		gstreamer_encode_cmd="$encode_cmd > ${log_filename}_${code1}.log"
		gstreamer_encode_multi_cmd="$gstreamer_encode_cmd"
	elif [ "$code1" == "h265" ]; then
		encode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} ! videoparse width=4096 height=2160 format=nv12 framerate=60/1 ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2${code1}enc ! queue ! perf ! fakesink -e"
		gstreamer_encode_cmd="$encode_cmd > ${log_filename}_${code1}.log"
		gstreamer_encode_multi_cmd="$gstreamer_encode_multi_cmd & $gstreamer_encode_cmd"
	else
		encode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} ! videoparse width=4096 height=2160 format=nv12 framerate=60/1 ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2${code1}enc ! queue ! perf ! fakesink -e"
		gstreamer_encode_cmd="$encode_cmd > ${log_filename}_${code1}.log"
		gstreamer_encode_multi_cmd="$gstreamer_encode_multi_cmd & $gstreamer_encode_cmd"
	fi
done
echo ''
echo -e "\e[0;34m ========= Running multi-codec + multi-stream to encode the video stream ========	\e[0m"
#echo $gstreamer_encode_multi_cmd
eval $gstreamer_encode_multi_cmd

echo ''
echo -e "\e[0;32m ========== Performance of encode the video in diff codec ============= \e[0m"
for code1 in ${CODEC1//,/ };
do
	Throughput=$(grep "mean_fps" "${log_filename}_${code1}.log" | tail -1 | awk '{print $12}')
	echo " Result of ${code1} throughput: $Throughput fps"
	Total_throughput=$(bc <<< "scale=2; $Total_throughput + $Throughput")
		# done
done
		echo -e "\e[0;32m ==================================================================== \e[0m"
		echo -e "\e[0;32m Total of MSMC (MutliStream + MultiCodec) for encode is : $Total_throughput fps \e[0m"
		echo -e "\e[0;32m ==================================================================== \e[0m"
		echo ''

echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"
