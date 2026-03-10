@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 移除视频封面，支持拖拽单个视频文件到此脚本上



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

if "%~1" == "" (
    echo.
    echo 请拖拽一个视频文件到此脚本上
    echo.
    pause
    exit /b 1
)

set "file_path=%~1"

setlocal disabledelayedexpansion
set "file_name=%~nx1"
set "dir_path=%~dp1"
setlocal enabledelayedexpansion

cd /d "!dir_path!"

echo --------------------------------------------------
echo 正在检查: !file_name!

set "has_cover=0"
for /f "delims=" %%c in ('ffprobe -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!file_name!" 2^>nul') do (
    if "%%c"=="1" (
        set "has_cover=1"
    )
)

if "!has_cover!"=="0" (
    echo 跳过，无封面
) else (
    echo 找到封面，正在移除
    set "temp_file=%temp%\MyBatch_%random%_%random%.mp4"
    
    :: 仅保留第一个视频流和所有音频流，以此移除作为第二个视频流的封面
    ffmpeg -i "!file_name!" -c copy -map 0:v:0 -map 0:a? "!temp_file!" -hide_banner -loglevel error

    if errorlevel 1 (
        echo 移除失败
        if exist "!temp_file!" del /f /q "!temp_file!" >nul
    ) else (
        del /f /q "!file_name!" >nul
        ren "!temp_file!" "!file_name!" >nul
        echo 移除成功
    )
)



echo.
pause
exit /b
