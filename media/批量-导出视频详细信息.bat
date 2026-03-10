@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 递归扫描当前目录下的视频文件，使用 ffprobe 导出其详细信息为 json 文件



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的"以管理员权限运行"，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

for /r %%f in (*.mp4 *.mkv *.mov *.avi *.wmv *.flv) do (
    if exist "%%f" (
        echo 正在处理: %%f
        ffprobe -v error -show_streams -show_format -print_format json "%%f" > "%%~dpnf.json"
    )
)

echo.
echo 处理完成，包含了视频详细信息的同名 .json 文件已保存



echo.
pause
exit /b
