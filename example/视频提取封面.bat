@echo off

echo 注意：需要修改时间参数

ffmpeg -i "output.mp4" -ss 00:00:40.000 -vframes 1 cover1.png
ffmpeg -i "output.mp4" -ss 00:00:40.200 -vframes 1 cover2.png
ffmpeg -i "output.mp4" -ss 00:00:40.300 -vframes 1 cover3.png
ffmpeg -i "output.mp4" -ss 00:00:40.400 -vframes 1 cover4.png
ffmpeg -i "output.mp4" -ss 00:00:40.500 -vframes 1 cover5.png
ffmpeg -i "output.mp4" -ss 00:00:40.600 -vframes 1 cover6.png
ffmpeg -i "output.mp4" -ss 00:00:40.700 -vframes 1 cover7.png
ffmpeg -i "output.mp4" -ss 00:00:40.800 -vframes 1 cover8.png
ffmpeg -i "output.mp4" -ss 00:00:40.900 -vframes 1 cover9.png



pause
exit
