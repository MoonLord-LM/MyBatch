@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 将视频封面导出为同名的 png 图片，支持拖拽单个视频文件到此脚本上



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
set "base_name=%~n1"
set "dir_path=%~dp1"
setlocal enabledelayedexpansion

cd /d "!dir_path!"

echo --------------------------------------------------
echo 正在检查: !file_name!

set "stream_index="
for /f "delims=" %%s in ('ffprobe -v error -select_streams v -show_entries stream^=index -disposition attached_pic -of csv^=p^=0 "!file_name!" 2^>nul') do (
    if not defined stream_index set "stream_index=%%s"
)

if not defined stream_index (
    echo 跳过，无封面
) else (
    set "cover_file=!base_name!.png"
    if exist "!cover_file!" (
        echo 跳过，封面图片已存在: !cover_file!
    ) else (
        echo 找到封面，正在导出到: !cover_file!
        ffmpeg -i "!file_name!" -map 0:!stream_index! -c copy "!cover_file!" -hide_banner -loglevel error

        if errorlevel 1 (
            echo 导出失败
            if exist "!cover_file!" del /f /q "!cover_file!" >nul
        ) else (
            echo 导出成功
        )
    )
)



echo.
pause
exit /b


