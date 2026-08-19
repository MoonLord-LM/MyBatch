@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '保留第 1 个文件的画面和元数据信息，将第 2 个文件的声音内容，替换到第 1 个文件中，生成一个新的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入两个视频文件的路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以选中两个视频文件，拖拽到此脚本上，自动识别处理；不支持拖入文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

REM 优先使用脚本所在文件夹中的 ffmpeg 和 ffprobe 组件
set "ffmpeg_path=ffmpeg"
if exist "%~dp0ffmpeg.exe" (
    set "ffmpeg_path=%~dp0ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
)
!ffmpeg_path! -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)
set "ffprobe_path=ffprobe"
if exist "%~dp0ffprobe.exe" (
    set "ffprobe_path=%~dp0ffprobe.exe"
) else if exist "!cd!\ffprobe.exe" (
    set "ffprobe_path=!cd!\ffprobe.exe"
)
!ffprobe_path! -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffprobe 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



setlocal disabledelayedexpansion
set "video1=%~1"
set "video2=%~2"
setlocal enabledelayedexpansion

if "!video1!"=="" (
    echo.
    echo 请输入要保留画面和元数据信息的视频文件路径
    echo 提示：可以直接将文件拖拽到窗口内
    set /p "video1="
)
if "!video2!"=="" (
    echo.
    echo 请输入提供声音内容的视频文件路径
    echo 提示：可以直接将文件拖拽到窗口内
    set /p "video2="
)

if exist "!video1!\" (
    echo 错误：不支持文件夹："!video1!"
    echo.
    pause
    exit /b 1
)
if not exist "!video1!" (
    echo 错误：文件不存在："!video1!"
    echo.
    pause
    exit /b 1
)
if exist "!video2!\" (
    echo 错误：不支持文件夹："!video2!"
    echo.
    pause
    exit /b 1
)
if not exist "!video2!" (
    echo 错误：文件不存在："!video2!"
    echo.
    pause
    exit /b 1
)

for %%i in ("!video1!") do (
    setlocal disabledelayedexpansion
    set "file_dir=%%~dpi"
    set "base_name=%%~ni"
    set "file_ext=%%~xi"
    setlocal enabledelayedexpansion
)
set "temp_file=!file_dir!!base_name!_temp!file_ext!"
set "output_file=!file_dir!!base_name!_声音替换!file_ext!"

echo.
echo 正在处理："!video1!"
echo 替换声音来自："!video2!"

"!ffmpeg_path!" -y -i "!video1!" -i "!video2!" -map 0:v? -map 1:a? -map_metadata 0 -map_chapters 0 -c copy "!temp_file!"
if !errorlevel! neq 0 (
    if exist "!temp_file!" ( del /f /q "!temp_file!" )
    echo.
    echo 声音替换失败
) else (
    move /y "!temp_file!" "!output_file!" >nul
    echo.
    echo 声音替换成功
    echo 输出文件："!output_file!"
)



echo.
pause
exit /b
