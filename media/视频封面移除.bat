@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



REM 移除视频封面
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
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"

        set "has_cover=0"
        for /f "delims=" %%c in ('ffprobe -v error -select_streams v:1 -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!file_dir!!video_file!" 2^>nul') do (
            if "%%c"=="1" (
                set "has_cover=1"
            )
        )

        if "!has_cover!"=="0" (
            echo set /a "skipped+=1" >> "!temp_set!"
            echo 无封面，跳过
        ) else (
            echo 找到封面，正在移除
            set "temp_file=%temp%\MyBatch_%random%_%random%!file_ext!"
            
            ffmpeg -i "!file_dir!!video_file!" -c copy -map 0 -map -0:v:1 "!temp_file!" -hide_banner -loglevel error

            if errorlevel 1 (
                echo set /a "failed+=1" >> "!temp_set!"
                if exist "!temp_file!" ( del /f /q "!temp_file!" )
                echo 移除失败
            ) else (
                echo set /a "succeeded+=1" >> "!temp_set!"
                del /f /q "!file_dir!!video_file!"
                ren "!temp_file!" "!video_file!"
                echo 移除成功
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
    set "file_ext=%~x1"
    setlocal enabledelayedexpansion

    echo 正在处理: "!video_file!"

    set "has_cover=0"
    for /f "delims=" %%c in ('ffprobe -v error -select_streams v:1 -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!file_dir!!video_file!" 2^>nul') do (
        if "%%c"=="1" (
            set "has_cover=1"
        )
    )

    if "!has_cover!"=="0" (
        echo 无封面，跳过
    ) else (
        echo 找到封面，正在移除
        set "temp_file=%temp%\MyBatch_%random%_%random%!file_ext!"
        
        ffmpeg -i "!file_dir!!video_file!" -c copy -map 0 -map -0:v:1 "!temp_file!" -hide_banner -loglevel error

        if errorlevel 1 (
            if exist "!temp_file!" ( del /f /q "!temp_file!" )
            echo 移除失败
        ) else (
            del /f /q "!file_dir!!video_file!"
            ren "!temp_file!" "!video_file!"
            echo 移除成功
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
