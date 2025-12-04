@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 将视频文件按录制开始时间重命名，统一为 VID_YYYYMMDD_HHMMSS.mp4 格式
:: 用视频的 creation_time 减去视频时长来计算录制开始时间，并转为中国时区

:: 依赖的软件 ffprobe.exe
:: https://github.com/FFmpeg/FFmpeg
:: ffprobe.exe -v quiet -select_streams v -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 + 文件名



for %%f in (*.mp4 *.mkv *.flv *.mov) do (
    set "file_name=%%f"
    set "creation_time="

    echo 处理文件："!file_name!"
    for /f "tokens=*" %%x in ('ffprobe.exe -v quiet -show_entries format_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!file_name!" 2^>nul') do (
        set "creation_time=%%x"
    )
    for /f "tokens=*" %%x in ('ffprobe.exe -v quiet -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!file_name!" 2^>nul') do (
        set "duration=%%x"
    )
    echo 原始创建时间："!creation_time!"
    echo 原始视频时长："!duration!"

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
            :: 调用 PowerShell 处理时区转换
            for /f "delims=" %%t in ('powershell -Command "& {param($utcTime, $duration) try { $dateTime = [DateTime]::ParseExact($utcTime, 'yyyy-MM-ddTHH:mm:ss.ffffffZ', $null); $startDateTime = $dateTime.AddSeconds(-[double]$duration); $startDateTime.ToString('yyyyMMdd_HHmmss') } catch { Write-Output 'ERROR' }} -utcTime '!creation_time!' -duration '!duration!'" 2^>nul') do (
                set "formatted_time=%%t"
            )
            if "!formatted_time!"=="ERROR" (
                echo 警告：时间格式解析错误，跳过此文件
            ) else (
                :: 保留原始文件扩展名
                set "new_name=VID_!formatted_time!"
                set "ext=%%~xf"
                set "new_name=!new_name!!ext!"
                echo 目标文件名："!new_name!"

                if "!file_name!"=="!new_name!" (
                    echo 目标文件名与原文件名相同，无需处理
                ) else if exist "!new_name!" (
                    echo 警告：目标文件已存在，跳过此文件
                ) else (
                    ren "!file_name!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo 重命名成功
                    ) else (
                        echo 警告：重命名失败，跳过此文件
                    )
                )
            )
        )
    )

    echo.
)

pause
exit
