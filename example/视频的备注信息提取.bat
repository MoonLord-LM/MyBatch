@echo off

:: 依赖的软件 ffprobe.exe
:: https://github.com/FFmpeg/FFmpeg
:: ffprobe.exe -v quiet -select_streams v -show_entries format_tags=comment -of default=noprint_wrappers=1:nokey=1 + 文件名



:: 创建或清空 comment.txt 文件
>"comment.txt" echo.

for %%f in (*.mp4) do (
    :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
    set "filename=%%f"
    setlocal enabledelayedexpansion
    echo 文件名 "!filename!"

    :: 使用 ffprobe 获取 comment 标签
    for /f "delims=" %%x in ('ffprobe.exe -v quiet -select_streams v -show_entries format_tags^=comment -of default^=noprint_wrappers^=1:nokey^=1 "!filename!" 2^>^&1') do (
        echo 备注 "%%x"
        echo %%x>>"comment.txt"
    )

    endlocal
    echo.
)



pause
exit