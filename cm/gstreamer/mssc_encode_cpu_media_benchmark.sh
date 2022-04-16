#! /bin/bash

declare stream=1
if [ $1 == "" ]; then
        stream=1
else
        stream=$1
fi

CODEC1="h264,h265,vp8,vp9"
video_src="Netflix_Aerial_4096x2160_60fps_10bit_420.y4m"
VIDEO_CONVERTOR="nvvideoconvert"
SYSTEM_ARCH=`uname -p`

## Check system Arch version - x86 or aarch64
if [ "${SYSTEM_ARCH}" == "aarch64" ]; then
        SUDO="sudo"
fi

for code1 in ${CODEC1//,/ };
do
        if [ "$code1" == "h264" ]; then
                encode_cmd="${SUDO} taskset -c 0-$(nproc) gst-launch-1.0 filesrc location=~/${video_src} ! videoparse width=4096 height=2160 format=nv12 framerate=60/1  ! queue ! x264enc ! queue ! perf ! fakesink -e"
        elif [ "$code1" == "h265" ]; then
                encode_cmd="${SUDO} taskset -c 0-$(nproc) gst-launch-1.0 filesrc location=~/${video_src} ! videoparse width=4096 height=2160 format=nv12 framerate=60/1  ! queue ! x265enc ! queue ! perf ! fakesink -e"
        else
                encode_cmd="${SUDO} taskset -c 0-$(nproc) gst-launch-1.0 filesrc location=~/${video_src} ! videoparse width=4096 height=2160 format=nv12 framerate=60/1 ! queue ! {code1}enc ! queue ! perf ! fakesink -e"
        fi

        log_filename="encode_gst_${code1}"
        rm *$log_filename*.log

        for (( num=1; num <= $stream; num++))
        do
                if [ $num -lt 2 ]; then
                        gstreamer_encode_cmd="$encode_cmd > $log_filename-$num.log"
                        gstreamer_encode_multi_cmd="$gstreamer_encode_cmd"
                else
                        gstreamer_encode_cmd="$encode_cmd > $log_filename-$num.log"
                        gstreamer_encode_multi_cmd="$gstreamer_encode_multi_cmd & $gstreamer_encode_cmd"
                fi

        done

        echo ''
        echo -e "\e[0;34m ========= Running codec ${code1} to encode the video stream ========  \e[0m"
        #echo $gstreamer_encode_multi_cmd
        eval $gstreamer_encode_multi_cmd
        sleep 10
        echo ''
        echo -e "\e[0;32m ========== Performance of encode the video in diff codec ============= \e[0m"
        for (( num=1; num <= $stream; num++))
        do

                if [ $num -lt 2 ]; then
                        Throughput=$(grep "mean_fps" "$log_filename-$num.log" | tail -1 | awk '{print $12}')
                        echo " Stream $num: $Throughput fps"
                        Total_throughput=$Throughput
                else
                        Throughput=$(grep "mean_fps" "$log_filename-$num.log" | tail -1 | awk '{print $12}')
                        echo " Stream $num: $Throughput fps"
                        Total_throughput=$(bc <<< "scale=2; $Total_throughput + $Throughput")
                fi
        done

        echo -e "\e[0;32m ====================================================== \e[0m"
        echo -e "\e[0;32m Throughput of codec in ${code1} is :  $Total_throughput fps \e[0m"
        echo -e "\e[0;32m ====================================================== \e[0m"
        echo ''
done
echo -e "\e[0;34m =============== Media becnhamrk Completed =============== \e[0m"
