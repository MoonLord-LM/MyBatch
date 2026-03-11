@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



REM 统计视频文件的编码参数
REM 双击运行时，自动递归扫描和处理当前目录下所有的视频文件
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



if "%~1" == "" (
    echo 开始扫描
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"
    set "temp_vcodecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.vcodecs" & type nul > "!temp_vcodecs!"
    set "temp_acodecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.acodecs" & type nul > "!temp_acodecs!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "failed=0"
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "video_file=%%~nxf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"
        ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of csv=p=0 "%%f" 2>nul >> "!temp_vcodecs!"
        ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,profile -of csv=p=0 "%%f" 2>nul >> "!temp_acodecs!"
        if errorlevel 1 (
            echo set /a "failed+=1">> "!temp_set!"
            echo 视频解析报错: "%%f"
        ) else (
            echo set /a "succeeded+=1">> "!temp_set!"
        )
        echo set /a "total+=1">> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!"

    echo.
    echo ----------------------------------------
    echo.

    REM 统计视频编码
    set /a "vcodec_count=0"
    echo 已发现的视频编码列表:
    (for /f "delims=" %%c in ('findstr /r "." "!temp_vcodecs!" ^| sort /uniq') do (
        set "vcodec=%%c"
        if "!vcodec:~-1!"=="," set "vcodec=!vcodec:~0,-1!"
        echo   !vcodec!
        set /a "vcodec_count+=1"
    )) & echo.

    REM 统计音频编码
    set /a "acodec_count=0"
    echo 已发现的音频编码列表:
    (for /f "delims=" %%c in ('findstr /r "." "!temp_acodecs!" ^| sort /uniq') do (
        set "acodec=%%c"
        if "!acodec:~-1!"=="," set "acodec=!acodec:~0,-1!"
        echo   !acodec!
        set /a "acodec_count+=1"
    )) & echo.

    echo ----------------------------------------
    echo.
    echo 统计完成
    echo 共计: !total! 个，成功: !succeeded! 个，失败: !failed! 个，发现 !vcodec_count! 种视频编码、!acodec_count! 种音频编码。

    if exist "!temp_set!" ( del /f /q "!temp_set!" )
    if exist "!temp_vcodecs!" ( del /f /q "!temp_vcodecs!" )
    if exist "!temp_acodecs!" ( del /f /q "!temp_acodecs!" )
) else (
    if not exist "%~1" (
        echo 错误: 文件不存在: "%~1"
        echo.
        pause
        exit /b 1
    )

    setlocal disabledelayedexpansion
    set "video_file=%~nx1"
    setlocal enabledelayedexpansion

    echo 正在处理: "!video_file!"
    set "vcodec_info="
    for /f "delims=" %%c in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name^,profile^,level -of csv^=p^=0 "%~1" 2^>nul') do (
        set "vcodec_info=%%c"
    )
    if defined vcodec_info if "!vcodec_info:~-1!"=="," set "vcodec_info=!vcodec_info:~0,-1!"
    
    set "acodec_info="
    for /f "delims=" %%c in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name^,profile -of csv^=p^=0 "%~1" 2^>nul') do (
        set "acodec_info=%%c"
    )
    if defined acodec_info if "!acodec_info:~-1!"=="," set "acodec_info=!acodec_info:~0,-1!"

    if errorlevel 1 (
        echo 视频解析报错: "!video_file!"
    ) else (
        echo.
        echo 视频编码: !vcodec_info!
        echo 音频编码: !acodec_info!
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
