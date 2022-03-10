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


TotalFrame=1000
rm ~/sample_output* ~/transcode_gst*

echo -e "\e[0;34m Total frame of video to use for decode and encode is set $TotalFrame as workload buffer. \e[0m"
echo -e "\e[0;34m       Start run video transcode and calculating performance, please wait....  \e[0m"

echo ''
echo -e "\e[0;34m ========= Running codec H264 (AVC to AVC) to transcode video into MP4 ========  \e[0m"
gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! vaapih264dec ! queue ! vaapih264enc bitrate=8000 ! mp4mux ! filesink location=sample_output_transcode_vaapi_h264.mp4 -e > ~/transcode_gst_vaapi_h264.log
sleep 10

echo ''
echo -e "\e[0;34m ========= Running codec H265 (AVC to HEVC) to transcode video into MP4  =========  \e[0m"
gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! vaapih264dec ! queue ! vaapih265enc bitrate=8000 ! mp4mux ! filesink location=sample_output_transcode_vaapi_h265.mp4 -e > ~/transcode_gst_vaapi_h265.log      
sleep 10

## Found VP8 & VP9 not support for GPU
#echo ''
#echo -e "\e[0;34m ========= Running codec VP8 (AVC to VP8) transcode video into MKV =========  \e[0m"
#gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! avdec_h264 ! queue ! vp8enc ! matroskamux ! filesink location=sample_output_transcode_vp8.mkv -e > ~/transcode_gst_vaapi_vp8.log
#sleep 10

#echo ''
#echo -e "\e[0;34m ========= Running codec VP9 (AVC to VP9) to transcode video into MKV =========  \e[0m"
#gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! avdec_h264 ! queue ! vp9enc ! matroskamux ! filesink location=sample_output_transcode_vp9.mkv -e > ~/transcode_gst_vaapi_vp9.log

echo ''
echo -e "\e[0;32m ========== Performance of transcode the video in diff codec ============= \e[0m"
TotalTime_vaapi_h264=$(grep "Execution ended" "~/transcode_gst_vaapi_h264.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
echo -e "\e[0;32m Total time to run on H264 (AVC) codec: $TotalTime_vaapi_h264 sec \e[0m"

TotalTime_vaapi_h265=$(grep "Execution ended" "~/transcode_gst_vaapi_h265.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
echo -e "\e[0;32m Total time to run on H265 (HEVC) codec: $TotalTime_vaapi_h265 sec \e[0m"

#TotalTime_vaapi_vp8=$(grep "Execution ended" "~/transcode_gst_vaapi_vp8.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
#echo -e "\e[0;32m Total time to run on VP8 codec: $TotalTime_vaapi_vp8 sec \e[0m"

#TotalTime_vaapi_vp9=$(grep "Execution ended" "~/transcode_gst_vaapi_vp9.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
#echo -e "\e[0;32m Total time to run on VP9 codec: $TotalTime_vaapi_vp9 sec \e[0m"

echo ''

TotalFrame=`ffmpeg -i ~/sample_output_transcode_vaapi_h264.mp4 -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' | sed 's/^.*\r/\r/' | awk '{print $2}' | grep -o '[0-9]\+'`


Throughput_vaapi_h264=$(bc <<< "scale=2; $TotalFrame / $TotalTime_vaapi_h264")
Throughput_vaapi_h265=$(bc <<< "scale=2; $TotalFrame / $TotalTime_vaapi_h265")
#Throughput_vaapi_vp8=$(bc <<< "scale=2; $TotalFrame / $TotalTime_vaapi_vp8")
#Throughput_vaapi_vp9=$(bc <<< "scale=2; $TotalFrame / $TotalTime_vaapi_vp9")

echo -e "\e[0;32m ====================================================== \e[0m"
echo ''
echo -e "\e[0;32m Throughput of codec in H264 is : $Throughput_vaapi_h264 fps \e[0m"
echo -e "\e[0;32m Throughput of codec in H265 is : $Throughput_vaapi_h265 fps \e[0m"
#echo -e "\e[0;32m Throughput of codec in VP8 is : $Throughput_vaapi_vp8 fps \e[0m"
#echo -e "\e[0;32m Throughput of codec in VP9 is : $Throughput_vaapi_vp9 fps \e[0m"
echo -e "\e[0;32m =============== Media becnhamrk Completed =============== \e[0m"
