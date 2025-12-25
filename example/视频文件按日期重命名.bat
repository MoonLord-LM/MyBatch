@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 将视频文件的创建日期添加到文件名开头，方便排序

:: 依赖的软件 ffprobe.exe
:: https://github.com/FFmpeg/FFmpeg
:: ffprobe.exe -v quiet -select_streams v -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 + 文件名



for %%f in (*.mp4 *.mkv *.flv *.mov) do (
    :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
    setlocal disabledelayedexpansion
    set "filename=%%f"
    setlocal enabledelayedexpansion
    echo 文件名 "!filename!"

    :: 使用 ffprobe 获取 date 标签
    for /f "delims=" %%x in ('ffprobe.exe -v quiet -select_streams v -show_entries format_tags^=date -of default^=noprint_wrappers^=1:nokey^=1 "%cd%\!filename!" 2^>^&1') do (
        echo 创建时间 date 标签 "%%x"
        set "filedate=%%x"
    )

    :: 检查是否获取到了日期
    if not "!filedate!" == "" (
        :: 如果文件名以日期开头，则跳过重命名
        echo !filename! | findstr /b /c:!filedate! >nul
        if !errorlevel! == 1 (
            echo 文件名修改为 "!filedate! !filename!"
            ren "!filename!" "!filedate! !filename!"
        ) else (
            echo 文件名已包含日期
        )
    ) else (
        echo 警告：未找到 date 信息 "!filename!"
        :: 使用 ffprobe 获取 creation_time 标签
        for /f "tokens=*" %%t in ('ffprobe.exe -v quiet -show_entries format_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!filename!" 2^>nul') do (
            set "creation_time=%%t"
        )
        if not defined creation_time (
            echo 警告：未找到 creation_time 信息，跳过此文件
        ) else (
            :: 示例 2000-01-01T00:00:00.000000Z
            set "suffix_part1=!creation_time:~19,8!"
            set "suffix_part2=!creation_time:~-8!"

            if not "!suffix_part1!"==".000000Z" (
                echo 警告：时间格式不正确，跳过此文件
            ) else if not "!suffix_part2!"==".000000Z" (
                echo 警告：时间格式不正确，跳过此文件
            ) else (
                set "filedate=!creation_time:~0,10!
                set "filedate=!filedate:-=!"
                echo 创建时间 creation_time 标签 "!filedate!"
                echo !filename! | findstr /b /c:!filedate! >nul
                if !errorlevel! == 1 (
                    echo 文件名修改为 "!filedate! !filename!"
                    ren "!filename!" "!filedate! !filename!"
                ) else (
                    echo 文件名已包含日期
                )
            )
        )
    )

    echo.
)



pause
exit
