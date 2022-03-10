#! /bin/bash

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


if [ "$1" == "" ]; then
        if [ $TotalFrame -gt 10000 ]; then
                TotalFrame=10000
        fi
else
        TotalFrame=$1
fi
echo -e "\e[0;34m Total frame of video to use for decode and encode is set $TotalFrame as workload buffer. \e[0m"
echo " "
echo -e "\e[0;34m       Start run video transcode and calculating performance, please wait....  \e[0m"

VIDEO_CONVERTOR="nvvideoconvert"
SYSTEM_ARCH=`uname -p`


if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        SUDO="sudo"
        VIDEO_CONVERTOR="nvvidconv"
fi
${SUDO} sample_output* transcode_gst*

        echo ''
        echo -e "\e[0;34m ========= Running codec H264 (AVC to AVC) to transcode video into MP4 ========  \e[0m"
        ${SUDO} gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2h264enc ! perf ! filesink location=sample_output_transcode_v4l2_h264.mp4 -e > transcode_gst_v4l2_h264.log
        sleep 10
        echo ''
        echo -e "\e[0;34m ========= Running codec H265 (AVC to HEVC) to transcode video into MP4  =========  \e[0m"
        ${SUDO} gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2h265enc ! perf ! filesink location=sample_transcode_output_v4l2_h265.mp4 -e > transcode_gst_v4l2_h265.log

if [ "${SYSTEM_ARCH}" == "aarch64" ]; then        
        #sleep 10
        #echo ''
        #echo -e "\e[0;34m ========= Running codec VP8 (AVC to VP8) transcode video into MKV =========  \e[0m"
        #sudo gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2vp8enc ! perf ! filesink location=sample_output_transcode_v4l2_vp8.mp4 -e > transcode_gst_v4l2_vp8.log
        sleep 10
        echo ''
        echo -e "\e[0;34m ========= Running codec VP9 (AVC to VP9) to transcode video into MKV =========  \e[0m"
        ${SUDO} gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! nvv4l2decoder ! queue ! ${VIDEO_CONVERTOR} ! queue ! nvv4l2vp9enc ! perf ! matroskamux ! filesink location=sample_output_transcode_v4l2_vp9.mkv -e > transcode_gst_v4l2_vp9.log
 fi
#TotalTime_h264=$(grep "Execution ended" "/tmp/gst_h264.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
#echo -e "\e[0;32m Total time to run on H264 (AVC) codec: $TotalTime_h264 sec \e[0m"

#TotalTime_h265=$(grep "Execution ended" "/tmp/gst_h265.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
#echo -e "\e[0;32m Total time to run on H265 (HEVC) codec: $TotalTime_h265 sec \e[0m"

echo ''
echo -e "\e[0;32m ========== Performance of transcode the video in diff codec ============= \e[0m"
TotalTime_v4l2_h264=$(grep "Execution ended" "/tmp/gst_v4l2_h264.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
echo -e "\e[0;32m Total time to run on v4l2 h264 (AVC) codec: $TotalTime_v4l2_h264 sec \e[0m"

TotalTime_v4l2_h265=$(grep "Execution ended" "/tmp/gst_v4l2_h265.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
echo -e "\e[0;32m Total time to run on v4l2 h265 (HEVC) codec: $TotalTime_v4l2_h265 sec \e[0m"

if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        #TotalTime_v4l2_vp8=$(grep "Execution ended" "/tmp/gst_v4l2_vp8.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
        #echo -e "\e[0;32m Total time to run on v4l2 VP8 codec: $TotalTime_v4l2_vp8 sec \e[0m"

        TotalTime_v4l2_vp9=$(grep "Execution ended" "/tmp/gst_v4l2_vp9.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
        echo -e "\e[0;32m Total time to run on v4l2 VP9 codec: $TotalTime_v4l2_vp9 sec \e[0m"
fi

echo ''
TotalFrame=`ffmpeg -i ~/sample_output_transcode_v4l2_h264.mp4 -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' | sed 's/^.*\r/\r/' | awk '{print $2}' | grep -o '[0-9]\+'`

#Throughput_h264=$(bc <<< "scale=2; $TotalFrame / $TotalTime_h264")
#Throughput_h265=$(bc <<< "scale=2; $TotalFrame / $TotalTime_h265")
Throughput_v4l2_h264=$(bc <<< "scale=2; $TotalFrame / $TotalTime_v4l2_h264")
Throughput_v4l2_h265=$(bc <<< "scale=2; $TotalFrame / $TotalTime_v4l2_h265")
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        #Throughput_v4l2_vp8=$(bc <<< "scale=2; $TotalFrame / $TotalTime_v4l2_vp8")
        Throughput_v4l2_vp9=$(bc <<< "scale=2; $TotalFrame / $TotalTime_v4l2_vp9")
fi
#echo -e "\e[0;32m Throughput of codec in h264 is : $Throughput_h264 fps \e[0m"
#echo -e "\e[0;32m Throughput of codec in h265 is : $Throughput_h265 fps \e[0m"
echo -e "\e[0;32m ====================================================== \e[0m"
echo ''
echo -e "\e[0;32m Throughput of codec in v4l2 H264 is : $Throughput_v4l2_h264 fps \e[0m"
echo -e "\e[0;32m Throughput of codec in v4l2 H265 is : $Throughput_v4l2_h265 fps \e[0m"
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        #echo -e "\e[0;32m Throughput of codec in v4l2 VP8 is : $Throughput_v4l2_vp8 fps \e[0m"
        echo -e "\e[0;32m Throughput of codec in v4l2 VP9 is : $Throughput_v4l2_vp9 fps \e[0m"
fi
echo ''
echo -e "\e[0;32m =============== Media becnhamrk Completed =============== \e[0m"
