@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 扫描当前目录下的 mp4 文件，移除视频封面



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

set "processed=0"
set "skipped=0"
set "failed=0"

for %%f in (*.mp4) do (
    setlocal disabledelayedexpansion
    set "file_name=%%f"
    setlocal enabledelayedexpansion

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
        set /a "skipped+=1"
    ) else (
        echo 找到封面，正在移除
        set "temp_file=%temp%\MyBatch_%random%_%random%.mp4"
        
        :: 仅保留第一个视频流和所有音频流，以此移除作为第二个视频流的封面
        ffmpeg -i "!file_name!" -c copy -map 0:v:0 -map 0:a? "!temp_file!" -hide_banner -loglevel error

        if errorlevel 1 (
            echo 移除失败
            set /a "failed+=1"
            if exist "!temp_file!" del /f /q "!temp_file!" >nul
        ) else (
            del /f /q "!file_name!" >nul
            ren "!temp_file!" "!file_name!" >nul
            echo 移除成功
            set /a "processed+=1"
        )
    )
    endlocal
    endlocal
)



echo.
echo ==================================================
echo 扫描完成
echo 成功: !processed!
echo 失败: !failed!
echo 跳过: !skipped!
echo ==================================================



echo.
pause
exit /b


