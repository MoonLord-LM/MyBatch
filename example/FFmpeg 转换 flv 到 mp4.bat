@echo off
echo 使用 FFmpeg，转换视频格式，从 flv 到 mp4

if "%~1"=="" (
    echo 请拖拽文件，到本文件图标上运行
    pause
    exit
)

set "ffmpeg=S:\Common\DouyuPCClient\Client\8.5.3.1\ffmpeg.exe"
echo "%ffmpeg%" -i "%~1" -c copy "%~1.mp4"

"%ffmpeg%" -i "%~1" -c copy "%~1.mp4"

echo 转换完成，请查看生成的 mp4 文件
pause
exit
