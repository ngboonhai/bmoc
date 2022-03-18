#! /bin/bash

export GST_VAAPI_ALL_DRIVERS=1
echo -e "\e[0;34m ========= Downloading the video clip - bbb_sunflower_2160p_60fps_normal.mp4, please wait... ========= \e[0m"
if [ ! -f ~/bbb_sunflower_2160p_60fps_normal_orig.mp4 ]; then
        curl -k http://ftp.vim.org/ftp/ftp/pub/graphics/blender/demo/movies/BBB/bbb_sunflower_2160p_60fps_normal.mp4 -o ~/bbb_sunflower_2160p_60fps_normal_orig.mp4
        cp ~/bbb_sunflower_2160p_60fps_normal_orig.mp4 ~/bbb_sunflower_2160p_60fps_normal.mp4
        echo -e "\e[0;34m =============== Vidoe Clip download Completed =============== \e[0m"
else
        rm ~/bbb_sunflower_2160p_60fps_normal.mp4
        cp ~/bbb_sunflower_2160p_60fps_normal_orig.mp4 ~/bbb_sunflower_2160p_60fps_normal.mp4
        echo -e "\e[0;34m =============== Vidoe Clip Existed =============== \e[0m"
fi

echo " "
TotalFrame=`ffmpeg -i ~/bbb_sunflower_2160p_60fps_normal.mp4 -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' | sed 's/^.*\r/\r/' | awk '{print $1}' | grep -o '[0-9]\+'`
echo -e "\e[0;34m Total frame of video detect : $TotalFrame \e[0m"

CODEC1="h264,h265,vp8,vp9"
CODEC2="h264,h265,vp8,vp9"
decode_cmd="gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! ${CODEC}parse ! queue ! vaapi${CODEC}dec ! queue ! qtmux ! perf ! filesink location=sample_output_vaapi_${CODEC}_decode.mp4 -e"
TotalFrame=1000
rm ~/sample_output* ~/gst_vaapi_*

echo -e "\e[0;34m Total frame of video to use for decode and encode is set $TotalFrame as workload buffer. \e[0m"
echo -e "\e[0;34m       Start run video transcode and calculating performance, please wait....  \e[0m"

for code1 in ${CODEC1//,/ }
do
	for code2 in ${CODEC2//./ }
	do
		echo ''
		echo -e "\e[0;34m ========= Running codec ${CODEC} to ${CODEC} to decode the video stream ========  \e[0m"
		decode_cmd="$decode_cmd > ~/gst_vaapi_transcode_${CODEC}.log"
		echo decode_cmd
		#eval decode_cmd
		#sleep 10
	done
done
