@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '查看视频文件的编码参数' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和统计当前目录下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只查看该文件；拖拽文件夹时，则递归查看其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffprobe -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误: 缺少 ffprobe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    echo 开始扫描
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"
    set "temp_video_codecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.video_codecs" & type nul > "!temp_video_codecs!"
    set "temp_audio_codecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.audio_codecs" & type nul > "!temp_audio_codecs!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "failed=0"
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"
        ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of csv=p=0 "!video_file!" 2>nul >> "!temp_video_codecs!"
        if !errorlevel! neq 0 (
            echo set /a "failed+=1">> "!temp_set!"
            echo 视频编码解析失败
        ) else (
            ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,profile -of csv=p=0 "!video_file!" 2>nul >> "!temp_audio_codecs!"
            if !errorlevel! neq 0 (
                echo set /a "failed+=1">> "!temp_set!"
                echo 音频编码解析失败
            ) else (
                echo set /a "succeeded+=1">> "!temp_set!"
            )
        )
        echo set /a "total+=1">> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo.
    echo ----------------------------------------
    echo.

    set /a "video_codec_count=0"
    echo 已发现的视频编码列表:
    (for /f "delims=" %%c in ('findstr /r "." "!temp_video_codecs!" ^| sort /uniq') do (
        set "video_codec=%%c"
        if "!video_codec:~-1!"=="," set "video_codec=!video_codec:~0,-1!"
        echo !video_codec!
        set /a "video_codec_count+=1"
    )) & echo.

    set /a "audio_codec_count=0"
    echo 已发现的音频编码列表:
    (for /f "delims=" %%c in ('findstr /r "." "!temp_audio_codecs!" ^| sort /uniq') do (
        set "audio_codec=%%c"
        if "!audio_codec:~-1!"=="," set "audio_codec=!audio_codec:~0,-1!"
        echo !audio_codec!
        set /a "audio_codec_count+=1"
    )) & echo.

    echo ----------------------------------------
    echo.
    echo 统计完成
    echo 共计: !total! 个，成功: !succeeded! 个，失败: !failed! 个，发现 !video_codec_count! 种视频编码、!audio_codec_count! 种音频编码。

    if exist "!temp_video_codecs!" ( del /f /q "!temp_video_codecs!" )
    if exist "!temp_audio_codecs!" ( del /f /q "!temp_audio_codecs!" )
) else (
    setlocal disabledelayedexpansion
    set "video_file=%~1"
    setlocal enabledelayedexpansion

    if not exist "!video_file!" (
        echo 错误: 文件不存在: "!video_file!"
        echo.
        pause
        exit /b 1
    )

    if exist "!video_file!\" (
        echo 开始处理文件夹: "!video_file!"
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"
        set "temp_video_codecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.video_codecs" & type nul > "!temp_video_codecs!"
        set "temp_audio_codecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.audio_codecs" & type nul > "!temp_audio_codecs!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "failed=0"
        for /r "!video_file!" %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
            setlocal disabledelayedexpansion
            set "video_file=%%f"
            setlocal enabledelayedexpansion

            echo 正在处理: "!video_file!"
            ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of csv=p=0 "!video_file!" 2>nul >> "!temp_video_codecs!"
            if !errorlevel! neq 0 (
                echo set /a "failed+=1">> "!temp_set!"
                echo 视频编码解析失败
            ) else (
                ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,profile -of csv=p=0 "!video_file!" 2>nul >> "!temp_audio_codecs!"
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    echo 音频编码解析失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                )
            )
            echo set /a "total+=1">> "!temp_set!"
            echo.

            endlocal
            endlocal
        )

        REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
        call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

        echo.
        echo ----------------------------------------
        echo.

        set /a "video_codec_count=0"
        echo 已发现的视频编码列表:
        (for /f "delims=" %%c in ('findstr /r "." "!temp_video_codecs!" ^| sort /uniq') do (
            set "video_codec=%%c"
            if "!video_codec:~-1!"=="," set "video_codec=!video_codec:~0,-1!"
            echo !video_codec!
            set /a "video_codec_count+=1"
        )) & echo.

        set /a "audio_codec_count=0"
        echo 已发现的音频编码列表:
        (for /f "delims=" %%c in ('findstr /r "." "!temp_audio_codecs!" ^| sort /uniq') do (
            set "audio_codec=%%c"
            if "!audio_codec:~-1!"=="," set "audio_codec=!audio_codec:~0,-1!"
            echo !audio_codec!
            set /a "audio_codec_count+=1"
        )) & echo.

        echo ----------------------------------------
        echo.
        echo 统计完成
        echo 共计: !total! 个，成功: !succeeded! 个，失败: !failed! 个，发现 !video_codec_count! 种视频编码、!audio_codec_count! 种音频编码。

        if exist "!temp_video_codecs!" ( del /f /q "!temp_video_codecs!" )
        if exist "!temp_audio_codecs!" ( del /f /q "!temp_audio_codecs!" )
    ) else (
        echo 开始处理文件: "!video_file!"

        set "video_codec="
        set "audio_codec="
        for /f "delims=" %%c in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,profile^,level -of csv^=p^=0 "!video_file!" 2^>nul') do (
            set "video_codec=%%c"
        )
        for /f "delims=" %%c in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "!video_file!" 2^>nul') do (
            set "audio_codec=%%c"
        )
        if "!video_codec!" == "" (
            echo 视频编码解析失败
        ) else (
            echo 视频编码: !video_codec!
        )
        if "!audio_codec!" == "" (
            echo 音频编码解析失败
        ) else (
            echo 音频编码: !audio_codec!
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
