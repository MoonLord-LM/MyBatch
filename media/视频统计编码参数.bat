@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 统计视频编码参数
:: 双击运行时，自动扫描并处理当前目录下所有格式的视频文件
:: 拖拽单个视频文件到此脚本上时，则只处理该文件



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

"ffprobe.exe" -version >nul 2>&1
if errorlevel 1 (
    echo 错误: 缺少 ffprobe.exe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    goto cleanup
)



set "videoCodecFile=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp"
set "audioCodecFile=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp"
if exist "%videoCodecFile%" del "%videoCodecFile%"
if exist "%audioCodecFile%" del "%audioCodecFile%"

if "%~1" == "" (
    echo.
    echo 未检测到输入文件，将自动扫描并处理当前目录下的所有视频文件。
    echo.
    echo 检查视频编码格式的 codec_name, codec_tag_string, profile, level
    echo 递归扫描 *.mp4, *.mkv, *.ts, *.avi, *.wmv, *.flv, *.rmvb, *.rm, *.vob, *.mpg, *.mpeg, *.3gp, *.m4v, *.f4v, *.mov, *.webm...
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        call :process_file "%%f"
    )
) else (
    call :process_file "%~1"
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

:cleanup
if exist "%videoCodecFile%" del "%videoCodecFile%"
if exist "%audioCodecFile%" del "%audioCodecFile%"



echo.
pause
exit /b


:process_file
    set "file_path=%~1"
    if not exist "%file_path%" goto :eof

    setlocal disabledelayedexpansion
    set "file_name=%~nx1"
    set "dir_path=%~dp1"
    setlocal enabledelayedexpansion

    if not "%dir_path%"=="" cd /d "%dir_path%"

    :: 处理视频编码
    for /f "delims=" %%v in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,codec_tag_string^,profile^,level -of csv^=p^=0 "!file_name!" 2^>nul') do (
        set "current_video_codec=%%v"
        if "!current_video_codec:~-1!"=="," set "current_video_codec=!current_video_codec:~0,-1!"
        if defined current_video_codec (
            if not exist "%videoCodecFile%" (
                echo 新增视频编码: !current_video_codec! - !file_name!
                >"%videoCodecFile%" echo(!current_video_codec!
            ) else (
                findstr /x /c:"!current_video_codec!" "%videoCodecFile%" >nul
                if errorlevel 1 (
                    echo 新增视频编码: !current_video_codec! - !file_name!
                    >>"%videoCodecFile%" echo(!current_video_codec!
                )
            )
        )
    )

    :: 处理音频编码
    for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "!file_name!" 2^>nul') do (
        set "current_audio_codec=%%a"
        if "!current_audio_codec:~-1!"=="," set "current_audio_codec=!current_audio_codec:~0,-1!"
        if defined current_audio_codec (
            if not exist "%audioCodecFile%" (
                echo 新增音频编码: !current_audio_codec! - !file_name!
                >"%audioCodecFile%" echo(!current_audio_codec!
            ) else (
                findstr /x /c:"!current_audio_codec!" "%audioCodecFile%" >nul
                if errorlevel 1 (
                    echo 新增音频编码: !current_audio_codec! - !file_name!
                    >>"%audioCodecFile%" echo(!current_audio_codec!
                )
            )
        )
    )

    endlocal
    endlocal
goto :eof
