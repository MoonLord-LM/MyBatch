@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion



::: 扫描当前目录及子目录中的 MP4 文件，统计并列出所有不重复的视频和音频编码信息

set "videoCodecFile=%temp%\video_codecs.txt"
set "audioCodecFile=%temp%\audio_codecs.txt"
del "%videoCodecFile%" "%audioCodecFile%" 2>nul

echo 检查依赖: ffprobe...
where ffprobe >nul 2>nul
if errorlevel 1 (
    echo 未找到 ffprobe，请先安装 FFmpeg 并配置 PATH。
    echo.
    pause
    exit /b 1
)

echo.
echo 检查视频编码格式（递归 *.mp4）...
for /r %%f in ("*.mp4") do (
    if exist "%%f" (
        for /f "delims=" %%v in ('
            ffprobe -v error -select_streams v^:0 -show_entries stream^=codec_name^,codec_tag_string^,profile^,level -of csv^=p^=0 "%%f" 2^>^&1
        ') do (
            set "current_video_codec=%%v"
            if defined current_video_codec (
                if not exist "%videoCodecFile%" (
                    echo new_video_codec: !current_video_codec! - %%f
                    >"%videoCodecFile%" echo(!current_video_codec!
                ) else (
                    findstr /x /c:"!current_video_codec!" "%videoCodecFile%" >nul 2>nul
                    if errorlevel 1 (
                        echo new_video_codec: !current_video_codec! - %%f
                        >>"%videoCodecFile%" echo(!current_video_codec!
                    )
                )
            )
        )
    )
)

echo.
echo 检查音频编码格式（递归 *.mp4）...
for /r %%f in ("*.mp4") do (
    if exist "%%f" (
        for /f "delims=" %%a in ('
            ffprobe -v error -select_streams a^:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "%%f" 2^>^&1
        ') do (
            set "current_audio_codec=%%a"
            if defined current_audio_codec (
                if not exist "%audioCodecFile%" (
                    echo new_audio_codec: !current_audio_codec! - %%f
                    >"%audioCodecFile%" echo(!current_audio_codec!
                ) else (
                    findstr /x /c:"!current_audio_codec!" "%audioCodecFile%" >nul 2>nul
                    if errorlevel 1 (
                        echo new_audio_codec: !current_audio_codec! - %%f
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



echo.
pause
exit /b
