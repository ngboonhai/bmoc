#! /bin/bash

declare stream=0

echo -e "\e[0;34m ========= Downloading the video clip - bbb_sunflower_2160p_60fps_normal.mp4, please wait... ========= \e[0m"
if [ ! -f ~/bbb_sunflower_2160p_60fps_normal_orig.mp4 ]; then
        curl -k http://ftp.vim.org/ftp/ftp/pub/graphics/blender/demo/movies/BBB/bbb_sunflower_2160p_60fps_normal.mp4 -o ~/bbb_sunfl
ower_2160p_60fps_normal_orig.mp4
        cp ~/bbb_sunflower_2160p_60fps_normal_orig.mp4 ~/bbb_sunflower_2160p_60fps_normal.mp4
        echo -e "\e[0;34m =============== Vidoe Clip download Completed =============== \e[0m"
else
        rm ~/bbb_sunflower_2160p_60fps_normal.mp4
        cp ~/bbb_sunflower_2160p_60fps_normal_orig.mp4 ~/bbb_sunflower_2160p_60fps_normal.mp4
        echo -e "\e[0;34m =============== Vidoe Clip Existed =============== \e[0m"
fi

if [ $1 == "" ]; then
        stream=1
else
        stream=$1
fi

TotalFrame=500

SYSTEM_ARCH=`uname -p`
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        SUDO="sudo"
fi

cmd="${SUDO} gst-launch-1.0 filesrc location=~/bbb_sunflower_2160p_60fps_normal.mp4 num-buffers=$TotalFrame ! qtdemux ! queue ! h264parse ! queue ! nvv4l2h264dec ! perf ! filesink location=sample_output_nvv4l2_h264_decode.mp4 -e"

log_filename="decode_gst_v4l2_h264"
rm *$log_filename*.log

for (( num=1; num <= $stream; num++))
do
        
        if [ $num -lt 2 ]; then
                gstreamer_log="$cmd > $log_filename-$num.log"
                gstreamer_cmd="$gstreamer_log"
        else
                gstreamer_log="$cmd > $log_filename-$num.log"
                gstreamer_cmd="$gstreamer_cmd & $gstreamer_log"
        fi

done
#echo $gstreamer_cmd
eval $gstreamer_cmd
sleep 10

TotalFrameDecoded=`ffmpeg -i ~/sample_output_nvv4l2_h264_decode.mp4 -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' | sed 's/^.*\r/\r/' | awk '{print $2}' | grep -o '[0-9]\+'`

echo " ==== Thoughput ==== "
for (( num=1; num <= $stream; num++))
do

        if [ $num -lt 2 ]; then
                TotalTime_v4l2_h264=$(grep "Execution ended" "$log_filename-$num.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
                Throughput_v4l2_h264=$(bc <<< "scale=2; $TotalFrameDecoded / $TotalTime_v4l2_h264")
                echo Stream $num: $Throughput_v4l2_h264 fps
                Total_throughput=$Throughput_v4l2_h264
        else
                TotalTime_v4l2_h264=$(grep "Execution ended" "$log_filename-$num.log" | awk '{print $4}' | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
                Throughput_v4l2_h264=$(bc <<< "scale=2; $TotalFrameDecoded / $TotalTime_v4l2_h264")
                echo Stream $num: $Throughput_v4l2_h264 fps
                Total_throughput=$(bc <<< "scale=2; $Total_throughput + $Throughput_v4l2_h264")
        fi
done
echo "============================="
echo "Total Throughtput of $stream Stream: $Total_throughput fps"
echo "============================="
