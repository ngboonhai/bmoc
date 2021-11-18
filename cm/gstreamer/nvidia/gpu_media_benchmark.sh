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
echo -e "\e[0;34m ========= Running video encoding and calculating performance, please wait.... =========  \e[0m"
SYSTEM_ARCH=`uname -p`
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        sudo gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! omxh264dec ! queue ! omxh264enc profile=8 ! matroskamux ! filesink location=sample_output_gpu.mkv -e > /tmp/gst.log
 else
        gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! nvv4l2decoder ! queue ! nvv4l2h264enc profile=4 bitrate=8000 ! filesink location=sample_output_cpu.mkv -e > /tmp/gst.log
fi
TotalTime=$(grep "Execution ended" "/tmp/gst.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
echo -e "\e[0;32m Total time to run: $TotalTime sec \e[0m"

Throughput=$(bc <<< "scale=2; $TotalFrame / $TotalTime")
echo -e "\e[0;32m Throughput is : $Throughput fps \e[0m"
echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"