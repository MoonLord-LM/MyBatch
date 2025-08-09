@echo off
setlocal enabledelayedexpansion
:: ffmpeg -i 1.mp4 -i 2.mp4 -map 1:v:0 -map 0:a -map 0:2 -map_metadata 0 -c copy -disposition:v:1 attached_pic output.mp4

echo.
echo 请输入原始视频文件路径（包含封面、音频、描述等）
set /p "video1="

if not exist "!video1!" (
    echo 文件 "!video1!" 不存在，请检查路径后重试。
    pause
    exit /b
)

echo.
echo 请输入用于替换视频流的文件路径（包含更高清的视频）
set /p "video2="

if not exist "!video2!" (
    echo 文件 "!video2!" 不存在，请检查路径后重试。
    pause
    exit /b
)

echo.
echo 正在执行视频合成命令，将第二个视频的视频流内容替换到第一个视频中...

echo ffmpeg -i !video1! -i !video2! -map 1:v:0 -map 0:a -map 0:2 -map_metadata 0 -c copy -disposition:v:1 attached_pic output.mp4
ffmpeg -i !video1! -i !video2! -map 1:v:0 -map 0:a -map 0:2 -map_metadata 0 -c copy -disposition:v:1 attached_pic output.mp4

echo.
echo 合成完成，生成文件为 output.mp4
pause
exit
