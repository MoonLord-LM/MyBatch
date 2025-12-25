@echo off
chcp 65001

echo.
echo 扫描当前目录下的 mp4 文件，将同名的 png/jpg 图片设置为视频封面
echo.

setlocal
set "processed=0"
set "skipped=0"
setlocal enabledelayedexpansion

for %%f in (*.mp4) do (
    :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
    endlocal
    set "filename=%%f"
    set "base_name=%%~nf"
    setlocal enabledelayedexpansion

    set "cover_file="
    set "has_cover=0"

    echo 检查 "!filename!"

    for /f "delims=" %%c in ('ffprobe -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!filename!" 2^>nul') do (
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
            echo 设置封面: !cover_file!
            ffmpeg -i "!filename!" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "temp_!filename!" -hide_banner -loglevel error

            if !errorlevel! equ 0 (
                del /f /q "!filename!" > nul
                ren "temp_!filename!" "!filename!" > nul
                echo 设置成功
                set /a "processed+=1"
            ) else (
                echo 设置失败
                if exist "temp_!filename!" del /f /q "temp_!filename!" > nul
            )
        ) else (
            echo 跳过，未找到封面图片
        )
    )
)

echo.
echo =================================================
echo 扫描完成
echo 已跳过 !skipped! 个文件
if "!processed!"=="0" (
    echo 未成功处理任何新文件
) else (
    echo 成功为 !processed! 个文件设置封面
)
echo =================================================

pause
exit
