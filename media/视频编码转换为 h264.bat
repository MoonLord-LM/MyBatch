@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



REM 视频编码转换为 h264 格式
REM 双击运行时，自动递归扫描和处理当前目录下所有的视频文件
REM 拖拽单个视频文件到此脚本上时，则只处理该文件
REM 支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffmpeg.exe -version >nul 2>&1
if errorlevel 1 (
    echo 错误: 缺少 ffmpeg.exe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
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

    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "file_dir=%%~dpf"
        set "video_file=%%~nxf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"

        set "is_h264=0"
        for /f "delims=" %%c in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 "!file_dir!!video_file!" 2^>nul') do (
            if /i "%%c"=="h264" (
                set "is_h264=1"
            )
        )

        if "!is_h264!"=="1" (
            echo set /a "skipped+=1" >> "!temp_set!"
            echo 视频编码已经是 h264，跳过
        ) else (
            set "output_file=!base_name!_h264.mp4"
            if exist "!file_dir!!output_file!" (
                echo set /a "skipped+=1" >> "!temp_set!"
                echo 已存在: "!output_file!"，跳过
            ) else (
                echo 正在转换为: "!output_file!"
                ffmpeg -i "!file_dir!!video_file!" -c:v libx264 -crf 23 -preset medium -c:a copy "!file_dir!!output_file!" -hide_banner -loglevel error
                if errorlevel 1 (
                    echo set /a "failed+=1" >> "!temp_set!"
                    if exist "!file_dir!!output_file!" ( del /f /q "!file_dir!!output_file!" )
                    echo 转换失败
                ) else (
                    echo set /a "succeeded+=1" >> "!temp_set!"
                    echo 转换成功
                )
            )
        )
        echo set /a "total+=1" >> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
) else (
    if not exist "%~1" (
        echo 错误: 文件不存在: "%~1"
        echo.
        pause
        exit /b 1
    )

    setlocal disabledelayedexpansion
    set "file_dir=%~dp1"
    set "video_file=%~nx1"
    set "base_name=%~n1"
    setlocal enabledelayedexpansion

    echo 正在处理: "!video_file!"

    set "is_h264=0"
    for /f "delims=" %%c in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 "!file_dir!!video_file!" 2^>nul') do (
        if /i "%%c"=="h264" (
            set "is_h264=1"
        )
    )

    if "!is_h264!"=="1" (
        echo 视频编码已经是 h264，跳过
    ) else (
        set "output_file=!base_name!_h264.mp4"
        if exist "!file_dir!!output_file!" (
            echo 已存在: "!output_file!"，跳过
        ) else (
            echo 正在转换为: "!output_file!"
            ffmpeg -i "!file_dir!!video_file!" -c:v libx264 -crf 23 -preset medium -c:a copy "!file_dir!!output_file!" -hide_banner -loglevel error
            if errorlevel 1 (
                if exist "!file_dir!!output_file!" ( del /f /q "!file_dir!!output_file!" )
                echo 转换失败
            ) else (
                echo 转换成功
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
