:: 全屏视频录制（MP4）
:: ffmpeg.exe -y -f gdigrab -i desktop -s 1920x1080 -r 20 -t 10.01 -c:v libx264 "record.mp4"



:: 全屏视频录制（HLS）
ffmpeg.exe -y -f gdigrab -i desktop -s 1280x720 -r 20 -c:v libx264 -hls_list_size 0 -g 40 -f segment -segment_list "playlist.m3u8" -segment_time 20.01 video-%%d.ts



pause
exit
