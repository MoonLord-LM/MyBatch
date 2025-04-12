@echo off
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/yt-dlp/yt-dlp
:: https://github.com/FFmpeg/FFmpeg



yt-dlp --update
yt-dlp --version

:loop
echo 请输入 YouTube 视频链接
set /p "url="

if "!url!"=="" (
    echo 输入不能为空，请重新输入
    goto loop
)

:: 检查是否是有效的URL
echo "!url!" | findstr /C:"https://www.youtube.com/watch?v=" >nul
if !errorlevel! == 1 (
    echo 输入的不是有效的 YouTube 链接，请重新输入
    goto loop
)

:: 删除 & 和后面的内容
if "!url!" neq "!url:&=!" (
    for /f "tokens=1 delims=&" %%i in ("!url!") do set "url=%%i"
)

:: 启动一个新的命令行窗口执行下载任务
echo 在新窗口中下载: "!url!"
set command1=yt-dlp.exe ^
 --list-formats ^
 --verbose ^
 ""!url!""
set command2=yt-dlp.exe ^
 --concurrent-fragments 20 ^
 -f ""bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"" ^
 --merge-output-format mp4 ^
 --embed-subs ^
 --embed-thumbnail ^
 --embed-metadata ^
 --embed-chapters ^
 --embed-info-json ^
 --verbose ^
 ""!url!""
start "" cmd /c "%command1% & %command2%"
echo.

goto loop
