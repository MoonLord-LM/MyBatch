@echo off
chcp 65001
setlocal enabledelayedexpansion

echo.
echo 扫描当前目录下的 mkv 文件，将同名的 ass/srt 字幕嵌入视频
echo.

set "processed=0"
set "skipped=0"

for %%f in (*.mkv) do (
    :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
    setlocal disabledelayedexpansion
    set "file_name=%%f"
    set "base_name=%%~nf"
    setlocal enabledelayedexpansion

    set "sub_file="
    set "has_sub=0"

    echo 检查 "!file_name!"

    for /f "delims=" %%s in ('ffprobe -v error -show_entries stream^=codec_type -of csv^=p^=0 "!file_name!" 2^>nul') do (
        if "%%s"=="subtitle" (
            set "has_sub=1"
        )
    )

    if "!has_sub!"=="1" (
        echo 跳过，已有字幕
        set /a "skipped+=1"
    ) else (
        if exist "!base_name!.ass" (
            set "sub_file=!base_name!.ass"
        ) else if exist "!base_name!.srt" (
            set "sub_file=!base_name!.srt"
        )

        if defined sub_file (
            echo 嵌入字幕: !sub_file!
            ffmpeg -i "!file_name!" -i "!sub_file!" -map 0 -map 1 -c copy -c:s copy "temp_!file_name!" -hide_banner -loglevel error

            if !errorlevel! equ 0 (
                del /f /q "!file_name!" > nul
                ren "temp_!file_name!" "!file_name!" > nul
                echo 嵌入成功
                set /a "processed+=1"
            ) else (
                echo 嵌入失败
                if exist "temp_!file_name!" del /f /q "temp_!file_name!" > nul
            )
        ) else (
            echo 跳过，未找到字幕文件
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
    echo 成功为 !processed! 个文件嵌入字幕
)
echo =================================================

pause
exit
