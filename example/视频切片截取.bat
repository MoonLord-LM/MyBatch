@echo off
chcp 65001
setlocal enabledelayedexpansion

echo.
echo 视频切片截取
echo.
echo 处理 ts 格式的文件时，建议先重新封装为 mp4 格式
echo.

:: 默认转码质量：-crf 16 -preset slow
:: 可改为更快的转码参数：-crf 23 -preset medium



:loop
    echo 请将要处理的视频文件拖拽到窗口中：
    set /p "input_file="
    set "input_file=!input_file:"=!"
    if "!input_file!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )
    if not exist "!input_file!" (
        echo 文件不存在，请重新输入
        goto loop
    )

    :input_begin_time
        echo 请输入开始时间（格式: HH:MM:SS.XXX）：
        set /p "begin_time="
        if "!begin_time!"=="" (
            echo 开始时间不能为空
            goto input_begin_time
        )

    :input_end_time
        echo 请输入结束时间（格式: HH:MM:SS.XXX）：
        set /p "end_time="
        if "!end_time!"=="" (
            echo 结束时间不能为空
            goto input_end_time
        )

    for %%f in ("!input_file!") do (
        set "filename=%%~nf"
    )
    set "output_file=!filename!_!begin_time::=!-!end_time::=!.mp4"

    echo 正在截取视频，请稍候...
    ffmpeg -ss "!begin_time!" -to "!end_time!" -i "!input_file!" -c:v libx264 -crf 16 -preset slow -c:a aac -b:a 320k "!output_file!" -movflags +faststart -y

    if !errorlevel! equ 0 (
        echo.
        echo 视频截取完成，输出文件：!output_file!
    ) else (
        echo.
        echo 视频截取失败
    )

    echo.
goto loop
