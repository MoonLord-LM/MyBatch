@echo off
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg



:loop
echo 请将要处理的视频文件拖拽到窗口中
set /p "url="

if "!url!"=="" (
    echo 输入不能为空，请重新输入
    goto loop
)

:: 启动一个新的命令行窗口
echo 在新窗口中处理: !url!
set command=ffmpeg.exe ^
 -i !url! ^
 -map 0:v:0 ^
 -map 0:a:0 ^
 -c copy ^
 -map -0:d:2 ^
 !url!.new.mp4
start "" cmd /c "%command%"
echo.

goto loop
