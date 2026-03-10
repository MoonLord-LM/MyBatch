@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 扫描当前目录下的 mp4 文件，将视频封面导出为同名的 png 图片



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

    echo --------------------------------------------------
    echo 正在检查: !file_name!

    set "stream_index="
    for /f "delims=" %%s in ('ffprobe -v error -select_streams v -show_entries stream^=index -disposition attached_pic -of csv^=p^=0 "!file_name!" 2^>nul') do (
        if not defined stream_index set "stream_index=%%s"
    )

    if not defined stream_index (
        echo 跳过，无封面
        set /a "skipped+=1"
    ) else (
        set "cover_file=!base_name!.png"
        if exist "!cover_file!" (
            echo 跳过，封面图片已存在: !cover_file!
            set /a "skipped+=1"
        ) else (
            echo 找到封面，正在导出到: !cover_file!
            ffmpeg -i "!file_name!" -map 0:!stream_index! -c copy "!cover_file!" -hide_banner -loglevel error

            if errorlevel 1 (
                echo 导出失败
                set /a "failed+=1"
                if exist "!cover_file!" del /f /q "!cover_file!" >nul
            ) else (
                echo 导出成功
                set /a "processed+=1"
            )
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


