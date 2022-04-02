#! /bin/bash

declare Total_throughput=0
CODEC1="h264,h264_265,h265"
#CODEC1="h264,h264_h265,h264_vp9,h265,h265_vp9,vp9"
TotalFrame=500
VIDEO_CONVERTOR="nvvideoconvert"
SYSTEM_ARCH=`uname -p`
log_filename="transcode_gst_${code1}"
rm *$log_filename*.log

## Check system Arch version - x86 or aarch64
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
		SUDO="sudo"
		VIDEO_CONVERTOR="nvvidconv"
fi


for code1 in ${CODEC1//,/ };
do
	if [ "$code1" == "h264" ]; then
		video_src="bbb_sunflower_2160p_60fps_normal.mp4"
		transcode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${code1}parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2${code1}enc ! queue ! perf ! fakesink -e"
		gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
		gstreamer_transcode_multi_cmd="$gstreamer_transcode_cmd"
	elif [ "$code1" == "h264_h265" ]; then
		code=h264
		video_src="bbb_sunflower_2160p_60fps_normal.mp4"
		transcode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${code}parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2h265enc ! queue ! perf ! fakesink -e"
		gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
		gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
	elif [ "$code1" == "h264_vp9" ]; then
		code=h264
		video_src="bbb_sunflower_2160p_60fps_normal.mp4"
		transcode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${code}parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2vp9enc ! queue ! perf ! fakesink -e"
		gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
		gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
	elif [ "$code1" == "h265" ]; then
		video_src="bbb_sunflower_2160p_60fps_normal.mkv"
		transcode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! matroskademux ! queue ! ${code1}parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2${code1}enc ! queue ! perf ! fakesink -e"
		gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
		gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
	elif [ "$code1" == "h265_vp9" ]; then
		code=h265
		video_src="bbb_sunflower_2160p_60fps_normal.mkv"
		transcode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! matroskademux ! queue ! ${code}parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2vp9enc ! queue ! perf ! fakesink -e"
		gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
		gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
	elif [ "$code1" == "vp9" ]; then
		video_src="bbb_sunflower_2160p_60fps_normal_${code1}.webm"
		transcode_cmd="${SUDO} gst-launch-1.0 filesrc location=~/${video_src} ! matroskademux ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2${code1}enc ! queue ! perf ! fakesink -e"
		gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
		gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
	fi
done
echo ''
echo -e "\e[0;34m ========= Running multi-codec + multi-stream to transcode the video stream ========	\e[0m"
#echo $gstreamer_transcode_multi_cmd
eval $gstreamer_transcode_multi_cmd

echo ''
echo -e "\e[0;32m ========== Performance of transcode the video in diff codec ============= \e[0m"
for code1 in ${CODEC1//,/ };
do
	Throughput=$(grep "mean_fps" "${log_filename}_${code1}.log" | tail -1 | awk '{print $12}')
	echo " Result of ${code1} throughput: $Throughput fps"
	Total_throughput=$(bc <<< "scale=2; $Total_throughput + $Throughput")
		# done
done
		echo -e "\e[0;32m ==================================================================== \e[0m"
		echo -e "\e[0;32m Total of MSMC (MutliStream + MultiCodec) for transcode is : $Total_throughput fps \e[0m"
		echo -e "\e[0;32m ==================================================================== \e[0m"
		echo ''

echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"
