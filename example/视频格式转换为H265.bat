@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg



set "convert=-vf yadif -c:v libx265 -preset veryslow -crf 12 -c:a aac -b:a 320k"

:loop
    echo 请将要处理的视频文件拖拽到窗口中，或者输入 mkv、flv、mov、vob 来自动转换当前目录下所有的输入格式的视频

    set /p "input="
    set "input=!input:"=!"
    if "!input!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    ) else if /i "!input!"=="mkv" (
        for %%f in (*.mkv) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            ffmpeg.exe -i "!file_name!" !convert! -map_metadata 0 -movflags +faststart "!file_name!.new.mp4"
            echo.
        )
        goto loop
    ) else if /i "!input!"=="flv" (
        for %%f in (*.flv) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            ffmpeg.exe -i "!file_name!" !convert! -map_metadata 0 -movflags +faststart "!file_name!.new.mp4"
            echo.
        )
        goto loop
    ) else if /i "!input!"=="mov" (
        for %%f in (*.mov) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            ffmpeg.exe -i "!file_name!" !convert! -map_metadata 0 -movflags +faststart "!file_name!.new.mp4"
            echo.
        )
        goto loop
    )  else if /i "!input!"=="vob" (
        for %%f in (*.vob) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            ffmpeg.exe -i "!file_name!" !convert! -map_metadata 0 -movflags +faststart "!file_name!.new.mp4"
            echo.
        )
        goto loop
    ) else (
        ffmpeg.exe -i "!input!" !convert! -map_metadata 0 -movflags +faststart "!input!.new.mp4"
    )
    echo.



goto loop
