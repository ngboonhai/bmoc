#! /bin/bash

export GST_VAAPI_ALL_DRIVERS=1

CODEC1="h264,h265,vp8,vp9"
TotalFrame=1000
rm ~/sample_output* ~/gst_vaapi_*

echo -e "\e[0;34m Total frame of video to use for decode and encode is set $TotalFrame as workload buffer. \e[0m"
echo -e "\e[0;34m       Start run video transcode and calculating performance, please wait....  \e[0m"

for code1 in ${CODEC1//,/ };
do
	if [ "$code1" == "h264" ]; then
		video_src="bbb_sunflower_2160p_60fps_normal.mp4"
		sample_output_video="sample_output_vaapi_${code1}_decode.mp4"
		decode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! qtdemux ! queue ! ${code1}parse ! queue ! vaapi${code1}dec ! queue ! qtmux ! perf ! filesink location=${sample_output_video} -e"
	elif [ "$code1" == "h265" ]; then
		video_src="bbb_sunflower_2160p_60fps_normal.mkv"
		sample_output_video="sample_output_vaapi_${code1}_decode.mkv"
		decode_cmd="gst-launch-1.0 filesrc location=~/${video_src} num-buffers=$TotalFrame ! matroskademux ! queue ! ${code1}parse ! queue ! vaapi${code1}dec ! queue ! matroskamux ! perf ! filesink location=${sample_output_video} -e"
	else
		video_src="bbb_sunflower_2160p_60fps_normal_${code1}.webm"
		sample_output_video="sample_output_vaapi_${code1}_decode.mkv"
		decode_cmd="gst-launch-1.0 filesrc location=~/${video_src} ! matroskademux ! vaapi${code1}dec ! queue ! matroskamux ! perf ! filesink location=${sample_output_video} -e"
	fi

	echo ''
	echo -e "\e[0;34m ========= Running codec ${code1} to decode the video stream ========  \e[0m"
	decoded_cmd="$decode_cmd > ~/gst_vaapi_decode_${code1}.log"
	#echo $decoded_cmd
	eval $decoded_cmd
	sleep 10
	echo ''
	echo -e "\e[0;32m ========== Performance of transcode the video in diff codec ============= \e[0m"
	TotalTime=$(grep "Execution ended" "gst_vaapi_decode_${code1}.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
	echo -e "\e[0;32m Total time to run on ${code1} codec: $TotalTime sec \e[0m"
	echo ''
	if [ "$code1" == "h264" ]; then
		TotalFrameOutput=`ffmpeg -i ~/${sample_output_video} -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' | sed 's/^.*\r/\r/' | awk '{print $2}' | grep -o '[0-9]\+'`
	else
		TotalFrameOutput=`ffmpeg -i ~/${sample_output_video} -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' | sed 's/^.*\r/\r/' | awk '{print $2}' | grep -o '[0-9]\+'`
	fi
	Throughput=$(bc <<< "scale=2; $TotalFrameOutput / $TotalTime")


	echo -e "\e[0;32m Throughput of codec in ${code1} is : $Throughput fps \e[0m"
	echo ''
	echo -e "\e[0;32m ====================================================== \e[0m"
	echo ''
done
echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"
