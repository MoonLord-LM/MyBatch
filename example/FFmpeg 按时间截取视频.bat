@echo off
echo 使用 FFmpeg，按时间截取视频，开始时间参数 -ss，结束时间参数 -to

if "%~1"=="" (
    echo 请拖拽文件，到本文件图标上运行
    pause
    exit
)

set "ffmpeg=S:\Common\DouyuPCClient\Client\8.5.2.2\ffmpeg.exe"
echo "%ffmpeg%" -i "%~1" -c copy -ss "03:29:22" -to "03:30:42" "%~1.clip.mp4"

"%ffmpeg%" -i "%~1" -c copy -ss "03:29:22" -to "03:30:42" "%~1.clip.mp4"

echo 截取完成，请查看生成的 mp4 文件
pause
exit
