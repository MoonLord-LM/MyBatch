@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg

echo.
echo 本脚本用于移除 MKV 视频的内嵌字幕
echo 可输入文件路径，将想要处理的视频文件拖拽到窗口中
echo 或者输入 mkv 这三个字母，以处理当前目录下的所有 mkv 文件
echo.

:loop
    set "processed=0"
    set "skipped=0"
    echo 请输入视频文件路径或 mkv：

    set /p "url="
    set "url=!url:"=!"  :: 去掉可能的引号
    if "!url!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )

    if /i "!url!"=="mkv" (
        for %%f in (*.mkv) do (
            :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
            setlocal disabledelayedexpansion
            set "file_name=%%f"
            setlocal enabledelayedexpansion

            echo 处理: "!file_name!"
            :: 移除所有字幕轨道
            ffmpeg.exe -i "!file_name!" -c copy -map 0 -map -0:s "temp_!file_name!" -hide_banner -loglevel error
            if !errorlevel! equ 0 (
                del /f /q "!file_name!" >nul
                ren "temp_!file_name!" "!file_name!" >nul
                set /a "processed+=1"
                echo 字幕移除成功
            ) else (
                echo 字幕移除失败
                if exist "temp_!file_name!" del /f /q "temp_!file_name!" > nul
            )
            echo.
            endlocal & set "processed=!processed!" & set "skipped=!skipped!"
        )
    ) else if exist "!url!" (
        for /f "delims=" %%f in ("!url!") do (
            echo 处理: "%%f"
            ffmpeg.exe -i "%%f" -c copy -map 0 -map -0:s "%%~dpnf.nosub.mkv" -hide_banner -loglevel error
        )
    ) else (
        echo 错误的输入
    )

    echo.
goto loop
