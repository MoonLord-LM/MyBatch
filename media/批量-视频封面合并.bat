@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 扫描当前目录下的 mp4 文件，将同名的 png/jpg 图片设置为视频封面



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
    set "base_name=%%~nf"
    setlocal enabledelayedexpansion

    set "cover_file="
    set "has_cover=0"

    echo --------------------------------------------------
    echo 正在检查: !file_name!

    for /f "delims=" %%c in ('ffprobe -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!file_name!" 2^>nul') do (
        if "%%c"=="1" (
            set "has_cover=1"
        )
    )

    if "!has_cover!"=="1" (
        echo 跳过，已有封面
        set /a "skipped+=1"
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
                set /a "failed+=1"
                if exist "!temp_file!" del /f /q "!temp_file!" >nul
            ) else (
                del /f /q "!file_name!" >nul
                ren "!temp_file!" "!file_name!" >nul
                echo 设置成功
                set /a "processed+=1"
            )
        ) else (
            echo 跳过，未找到封面图片
            set /a "skipped+=1"
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
