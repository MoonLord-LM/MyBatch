@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



REM 对视频文件统计编码参数
REM 双击运行时，自动扫描并处理当前目录下所有格式的视频文件
REM 拖拽单个视频文件到此脚本上时，则只处理该文件
REM 支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffprobe.exe -version >nul 2>&1
if errorlevel 1 (
    echo 错误: 缺少 ffprobe.exe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)

set /a "total=0"
set /a "video_codec_count=0"
set /a "audio_codec_count=0"

if "%~1" == "" (
    echo 未检测到输入文件，将自动扫描并处理当前目录下的所有视频文件。
    echo.
    echo 检查视频编码格式的 codec_name, codec_tag_string, profile, level
    echo 递归扫描视频文件...
    echo.

    set "temp_video_codecs=%temp%\MyBatch_vcodecs_%random%.tmp"
    set "temp_audio_codecs=%temp%\MyBatch_acodecs_%random%.tmp"
    type nul > "!temp_video_codecs!"
    type nul > "!temp_audio_codecs!"

    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        set /a "total+=1"
        echo 正在处理: "%%f"
        ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,codec_tag_string^,profile^,level -of csv^=p^=0 "%%f" 2>nul >> "!temp_video_codecs!"
        ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "%%f" 2>nul >> "!temp_audio_codecs!"
    )

) else (
    if not exist "%~1" (
        echo 错误: 文件不存在: "%~1"
        echo.
        pause
        exit /b 1
    )
    set "file_path=%~1"
    set /a "total+=1"
    echo 正在处理: "%file_path%"

    REM 处理视频编码
    for /f "delims=" %%v in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,codec_tag_string^,profile^,level -of csv^=p^=0 "%file_path%" 2^>nul') do (
        set "codec=%%v"
        if "!codec:~-1!"=="," set "codec=!codec:~0,-1!"
        if defined codec (
            if not defined video_codec_!codec! (
                set "video_codec_!codec!=!codec!"
                set /a "video_codec_count+=1"
                echo   [视频] 新增编码: !codec!
            )
        )
    )

    REM 处理音频编码
    for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "%file_path%" 2^>nul') do (
        set "codec=%%a"
        if "!codec:~-1!"=="," set "codec=!codec:~0,-1!"
        if defined codec (
            if not defined audio_codec_!codec! (
                set "audio_codec_!codec!=!codec!"
                set /a "audio_codec_count+=1"
                echo   [音频] 新增编码: !codec!
            )
        )
    )
    set /a "processed+=1"
    echo.
)

echo.
echo ----------------------------------------
echo.
echo 已发现的视频编码列表 (!video_codec_count! 个):
for /f "tokens=2 delims==" %%v in ('set video_codec_') do (
    echo %%v
)

echo.
echo 已发现的音频编码列表 (!audio_codec_count! 个):
for /f "tokens=2 delims==" %%a in ('set audio_codec_') do (
    echo %%a
)

echo.
echo ----------------------------------------
echo.
echo 统计完成: 共计 !total! 个文件，成功处理 !processed! 个。

echo.
pause
exit /b
