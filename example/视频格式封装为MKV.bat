@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg



:loop
    echo 请将要处理的视频文件拖拽到窗口中，或者输入 mp4、flv、mov、vob 来自动封装当前目录下所有的输入格式的视频

    set /p "input="
    set "input=!input:"=!"
    if "!input!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    ) else if /i "!input!"=="mp4" (
        for %%f in (*.mp4) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            if not exist "!file_name!.mkv" (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.new.mkv"
            ) else (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.mkv"
            )
            echo.
        )
        goto loop
    ) else if /i "!input!"=="flv" (
        for %%f in (*.flv) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            if not exist "!file_name!.mkv" (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.new.mkv"
            ) else (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.mkv"
            )
            echo.
        )
        goto loop
    ) else if /i "!input!"=="mov" (
        for %%f in (*.mov) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            if not exist "!file_name!.mkv" (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.new.mkv"
            ) else (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.mkv"
            )
            echo.
        )
        goto loop
    )  else if /i "!input!"=="vob" (
        for %%f in (*.vob) do (
            set "file_name=%%f"
            echo 开始处理 !file_name!
            if not exist "!file_name!.mkv" (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.new.mkv"
            ) else (
                ffmpeg.exe -i "!file_name!" -c copy -map_metadata 0 -movflags +faststart "!file_name!.mkv"
            )
            echo.
        )
        goto loop
    ) else (
        if not exist "!input!.mkv" (
            ffmpeg.exe -i "!input!" -c copy -map_metadata 0 -movflags +faststart "!input!.new.mkv"
        ) else (
            ffmpeg.exe -i "!input!" -c copy -map_metadata 0 -movflags +faststart "!input!.mkv"
        )
    )
    echo.



goto loop
