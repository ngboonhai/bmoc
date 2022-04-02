#! /bin/bash

export GST_VAAPI_ALL_DRIVERS=1
CODEC1="h264,h264_265,h265"
TotalFrame=500
log_filename="transcode_gst"
rm *$log_filename*.log

for code1 in ${CODEC1//,/ };
do
		if [ "$code1" == "h264" ]; then
				video_src="bbb_sunflower_2160p_60fps_normal.mp4"
				transcode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${code1}parse ! queue ! vaapi${code1}dec ! queue ! vaapi${code1}enc bitrate=8000 rate-control=cbr tune=high-compression ! queue ! perf ! fakesink -e"
				gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
				gstreamer_transcode_multi_cmd="$gstreamer_transcode_cmd"
		elif [ "$code1" == "h265" ]; then
				video_src="bbb_sunflower_2160p_60fps_normal.mkv"
				transcode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! matroskademux ! queue ! ${code1}parse ! queue ! vaapi${code1}dec  ! queue ! vaapi${code1}enc bitrate=8000 tune=low-power low-delay-b=1 ! queue ! perf ! fakesink -e"
				gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
				gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
		elif [ "$code1" == "h264_265" ]; then
				decode="h264"
                		encode="h265"
               			video_src="bbb_sunflower_2160p_60fps_normal.mp4"
				transcode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${decode}parse ! queue ! vaapi${decode}dec  ! queue ! vaapi${encode}enc bitrate=8000 tune=low-power low-delay-b=1 ! queue ! perf ! fakesink -e"
				gstreamer_transcode_cmd="$transcode_cmd > ${log_filename}_${code1}.log"
				gstreamer_transcode_multi_cmd="$gstreamer_transcode_multi_cmd & $gstreamer_transcode_cmd"
		fi
done
echo ''
echo -e "\e[0;34m ========= Running multi-codec + multi-stream to video stream ========	\e[0m"
echo $gstreamer_transcode_multi_cmd
#eval $gstreamer_transcode_multi_cmd

# echo ''
# echo -e "\e[0;32m ========== Performance of transcode the video in diff codec ============= \e[0m"
# for code1 in ${CODEC1//,/ };
# do
	# Throughput=$(grep "mean_fps" "${log_filename}_${code1}.log" | tail -1 | awk '{print $12}')
	# echo " Result of ${code1} throughput: $Throughput fps"
	# Total_throughput=$Throughput
	# Total_throughput=$(bc <<< "scale=2; $Total_throughput + $Throughput")
		# # done
# done
		# echo -e "\e[0;32m ====================================================== \e[0m"
		# echo -e "\e[0;32m Total of MSMC (MutliStream + MultiCodec) is :	$Total_throughput fps \e[0m"
		# echo -e "\e[0;32m ====================================================== \e[0m"
		# echo ''

# echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"
