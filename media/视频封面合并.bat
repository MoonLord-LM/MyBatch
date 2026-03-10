@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 将同名的 png/jpg 图片设置为视频封面，支持拖拽单个视频文件到此脚本上



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

set "cover_file="
set "has_cover=0"

cd /d "!dir_path!"

echo --------------------------------------------------
echo 正在检查: !file_name!

for /f "delims=" %%c in ('ffprobe -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!file_name!" 2^>nul') do (
    if "%%c"=="1" (
        set "has_cover=1"
    )
)

if "!has_cover!"=="1" (
    echo 跳过，已有封面
) else (
    if exist "!base_name!.png" (
        set "cover_file=!base_name!.png"
    ) else if exist "!base_name!.jpg" (
        set "cover_file=!base_name!.jpg"
    )

    if defined cover_file (
        echo 找到封面: !cover_file!
        set "temp_file=%temp%\MyBatch_%random%_%random%.mp4"
        ffmpeg -i "!file_name!" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "!temp_file!" -hide_banner -loglevel error

        if errorlevel 1 (
            echo 设置失败
            if exist "!temp_file!" del /f /q "!temp_file!" >nul
        ) else (
            del /f /q "!file_name!" >nul
            ren "!temp_file!" "!file_name!" >nul
            echo 设置成功
        )
    ) else (
        echo 跳过，未找到封面图片
    )
)



echo.
pause
exit /b
