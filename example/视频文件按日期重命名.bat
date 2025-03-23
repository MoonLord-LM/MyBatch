@echo off

:: 将视频文件的创建日期添加到文件名开头，方便排序

:: 依赖的软件 ffprobe.exe
:: https://github.com/FFmpeg/FFmpeg
:: ffprobe.exe -v quiet -select_streams v -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 + 文件名



for %%f in (*.mp4) do (
    :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
    set "filename=%%f"
    setlocal enabledelayedexpansion
    echo 文件名 "!filename!"

    :: 使用 ffprobe 获取 date 标签
    for /f "delims=" %%x in ('ffprobe.exe -v quiet -select_streams v -show_entries format_tags^=date -of default^=noprint_wrappers^=1:nokey^=1 "!filename!" 2^>^&1') do (
        echo 创建时间 "%%x"
        set "filedate=%%x"
    )

    :: 检查是否获取到了日期
    if "!filedate!" == "" (
        echo 未找到日期信息 "!filename!"
    ) else (
        :: 如果文件名以日期开头，则跳过重命名
        echo !filename! | findstr /b /c:!filedate! >nul
        if !errorlevel! == 1 (
            echo 文件名修改为 "!filedate! !filename!"
            ren "!filename!" "!filedate! !filename!"
        ) else (
            echo 文件名已包含日期
        )
    )

    endlocal
    echo.
)



pause
exit
