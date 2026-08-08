@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '导出视频字幕为同名的 srt 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffmpeg -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误: 缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
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

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"
        set "sub_file=!file_dir!!base_name!.srt"
        if exist "!sub_file!" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 已存在: "!sub_file!"，跳过此文件
        ) else (
            set "has_sub=0"
            for /f "delims=" %%s in ('ffprobe -v error -select_streams s -show_entries stream^=index -of csv^=p^=0 "!video_file!" 2^>nul') do (
                set "has_sub=1"
                set "stream_index=%%s"
            )

            if "!has_sub!"=="0" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 无字幕
            ) else (
                ffmpeg -i "!video_file!" -map 0:!stream_index! "!sub_file!"
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    if exist "!sub_file!" ( del /f /q "!sub_file!" )
                    echo 导出失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 保存文件: "!sub_file!"
                )
            )
        )
        echo set /a "total+=1">> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
) else (
    setlocal disabledelayedexpansion
    set "video_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    setlocal enabledelayedexpansion

    if not exist "!video_file!" (
        echo 错误: 文件不存在: "!video_file!"
        echo.
        pause
        exit /b 1
    )

    echo 正在处理: "!video_file!"
    set "sub_file=!file_dir!!base_name!.srt"
    if exist "!sub_file!" (
        echo 已存在: "!sub_file!"，跳过此文件
    ) else (
        set "has_sub=0"
        for /f "delims=" %%s in ('ffprobe -v error -select_streams s -show_entries stream^=index -of csv^=p^=0 "!video_file!" 2^>nul') do (
            set "has_sub=1"
            set "stream_index=%%s"
        )

        if "!has_sub!"=="0" (
            echo 无字幕
        ) else (
            ffmpeg -i "!video_file!" -map 0:!stream_index! "!sub_file!"
            if !errorlevel! neq 0 (
                if exist "!sub_file!" ( del /f /q "!sub_file!" )
                echo 导出失败
            ) else (
                echo 保存文件: "!sub_file!"
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
