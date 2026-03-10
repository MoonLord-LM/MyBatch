@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 递归扫描当前目录下的视频文件，统计并列出所有不重复的视频和音频编码信息。



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的"以管理员权限运行"，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

set "videoCodecFile=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp"
set "audioCodecFile=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp"
if exist "%videoCodecFile%" del "%videoCodecFile%"
if exist "%audioCodecFile%" del "%audioCodecFile%"

echo 检查依赖: ffprobe...
"ffprobe.exe" -version >nul 2>&1
if errorlevel 1 (
    echo 错误: 缺少 ffprobe.exe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    if exist "%videoCodecFile%" del "%videoCodecFile%"
    if exist "%audioCodecFile%" del "%audioCodecFile%"
    echo.
    pause
    exit /b 1
)

echo.
echo 检查视频编码格式的 codec_name, codec_tag_string, profile, level
echo 递归扫描 *.mp4, *.mkv, *.mov, *.avi, *.wmv, *.flv...
for /r %%f in ("*.mp4", "*.mkv", "*.mov", "*.avi", "*.wmv", "*.flv") do (
    if exist "%%f" (
        for /f "delims=" %%v in ('
            ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,codec_tag_string^,profile^,level -of csv^=p^=0 "%%f"
        ') do (
            set "current_video_codec=%%v"
            if "!current_video_codec:~-1!"=="," set "current_video_codec=!current_video_codec:~0,-1!"
            if defined current_video_codec (
                if not exist "%videoCodecFile%" (
                    echo 新增: !current_video_codec! - %%f
                    >"%videoCodecFile%" echo(!current_video_codec!
                ) else (
                    findstr /x /c:"!current_video_codec!" "%videoCodecFile%" >nul
                    if errorlevel 1 (
                        echo 新增: !current_video_codec! - %%f
                        >>"%videoCodecFile%" echo(!current_video_codec!
                    )
                )
            )
        )
    )
)

echo.
echo 检查音频编码格式的 codec_name, profile
echo 递归扫描 *.mp4, *.mkv, *.mov, *.avi, *.wmv, *.flv...
for /r %%f in ("*.mp4", "*.mkv", "*.mov", "*.avi", "*.wmv", "*.flv") do (
    if exist "%%f" (
        for /f "delims=" %%a in ('
            ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "%%f"
        ') do (
            set "current_audio_codec=%%a"
            if "!current_audio_codec:~-1!"=="," set "current_audio_codec=!current_audio_codec:~0,-1!"
            if defined current_audio_codec (
                if not exist "%audioCodecFile%" (
                    echo 新增: !current_audio_codec! - %%f
                    >"%audioCodecFile%" echo(!current_audio_codec!
                ) else (
                    findstr /x /c:"!current_audio_codec!" "%audioCodecFile%" >nul
                    if errorlevel 1 (
                        echo 新增: !current_audio_codec! - %%f
                        >>"%audioCodecFile%" echo(!current_audio_codec!
                    )
                )
            )
        )
    )
)

echo.
echo 已发现的视频编码列表:
if exist "%videoCodecFile%" (
    type "%videoCodecFile%"
) else (
    echo 无
)

echo.
echo 已发现的音频编码列表:
if exist "%audioCodecFile%" (
    type "%audioCodecFile%"
) else (
    echo 无
)

if exist "%videoCodecFile%" del "%videoCodecFile%"
if exist "%audioCodecFile%" del "%audioCodecFile%"



echo.
pause
exit /b
