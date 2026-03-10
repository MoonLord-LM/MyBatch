@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 视频编码转换为 h264 格式
:: 双击运行时，自动扫描并处理当前目录下所有格式的视频文件
:: 拖拽单个视频文件到此脚本上时，则只处理该文件



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
    echo.
    echo 未检测到输入文件，将自动扫描并处理当前目录下的所有视频文件。
    echo.
    set "processed=0"
    set "skipped=0"
    set "failed=0"
    for %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        call :process_file "%%f"
    )
    echo.
    echo 批量处理完成
    echo 成功: !processed!
    echo 失败: !failed!
    echo 跳过: !skipped!
) else (
    call :process_file "%~1"
)



echo.
pause
exit /b


:process_file
    set "file_path=%~1"
    setlocal disabledelayedexpansion
    set "file_name=%~nx1"
    set "base_name=%~n1"
    set "dir_path=%~dp1"
    setlocal enabledelayedexpansion

    if not "%dir_path%"=="" cd /d "%dir_path%"

    echo 正在处理: !file_name!

    set "is_h264=0"
    for /f "delims=" %%c in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of csv^=p^=0 "!file_name!" 2^>nul') do (
        if /i "%%c"=="h264" (
            set "is_h264=1"
        )
    )

    if "!is_h264!"=="1" (
        echo 跳过，视频编码已经是h264
        if defined processed set /a "skipped+=1"
    ) else (
        set "output_file=!base_name!_h264.mp4"
        if exist "!output_file!" (
            echo 跳过，目标文件已存在: !output_file!
            if defined processed set /a "skipped+=1"
        ) else (
            echo 正在转换为: !output_file!
            ffmpeg -i "!file_name!" -c:v libx264 -crf 23 -preset medium -c:a copy "!output_file!" -hide_banner -loglevel error

            if errorlevel 1 (
                echo 转换失败
                if exist "!output_file!" del /f /q "!output_file!" >nul
                if defined processed set /a "failed+=1"
            ) else (
                echo 转换成功
                if defined processed set /a "processed+=1"
            )
        )
    )
    endlocal
    endlocal
goto :eof
