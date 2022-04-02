#! /bin/bash

export GST_VAAPI_ALL_DRIVERS=1
CODEC1="h264,h265,vp8,vp9"
TotalFrame=500
log_filename="decode_gst"
rm *$log_filename*.log

for code1 in ${CODEC1//,/ };
do
		if [ "$code1" == "h264" ]; then
				video_src="bbb_sunflower_2160p_60fps_normal.mp4"
				decode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${code1}parse ! queue ! vaapi${code1}dec ! queue ! perf ! fakesink -e"
				gstreamer_decode_cmd="$decode_cmd > ${log_filename}_${code1}.log"
				gstreamer_decode_multi_cmd="$gstreamer_decode_cmd"
		elif [ "$code1" == "h265" ]; then
				video_src="bbb_sunflower_2160p_60fps_normal.mkv"
				decode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! matroskademux ! queue ! ${code1}parse ! queue ! vaapi${code1}dec ! queue ! perf ! fakesink -e"
				gstreamer_decode_cmd="$decode_cmd > ${log_filename}_${code1}.log"
				gstreamer_decode_multi_cmd="$gstreamer_decode_multi_cmd & $gstreamer_decode_cmd"
		else
				video_src="bbb_sunflower_2160p_60fps_normal_${code1}.webm"
				decode_cmd="gst-launch-1.0 filesrc location=~/${video_src} ! matroskademux ! vaapi${code1}dec ! queue ! perf ! fakesink -e"
				gstreamer_decode_cmd="$decode_cmd > ${log_filename}_${code1}.log"
				gstreamer_decode_multi_cmd="$gstreamer_decode_multi_cmd & $gstreamer_decode_cmd"
		fi
done
echo ''
echo -e "\e[0;34m ========= Running multi-codec + multi-stream to video stream ========	\e[0m"
#echo $gstreamer_decode_multi_cmd
eval $gstreamer_decode_multi_cmd

echo ''
echo -e "\e[0;32m ========== Performance of decode the video in diff codec ============= \e[0m"
for code1 in ${CODEC1//,/ };
do
	Throughput=$(grep "mean_fps" "${log_filename}_${code1}.log" | tail -1 | awk '{print $12}')
	echo " Result of ${code1} throughput: $Throughput fps"
	Total_throughput=$Throughput
	Total_throughput=$(bc <<< "scale=2; $Total_throughput + $Throughput")
		# done
done
		echo -e "\e[0;32m ====================================================== \e[0m"
		echo -e "\e[0;32m Total of MSMC (MutliStream + MultiCodec) is :	$Total_throughput fps \e[0m"
		echo -e "\e[0;32m ====================================================== \e[0m"
		echo ''

echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"
