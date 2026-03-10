@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 递归扫描当前目录下的视频文件，使用 ffprobe 导出其详细信息为 json 文件



for /r %%f in (*.mp4 *.mkv *.mov *.avi *.wmv *.flv) do (
    if exist "%%f" (
        echo 正在处理: %%f
        ffprobe -v error -show_streams -show_format -print_format json "%%f" > "%%~dpnf.json"
    )
)

echo 处理完成，结果已保存到当前目录下



echo.
pause
exit /b
