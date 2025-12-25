@echo off
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg

echo.
echo 本脚本用于移除视频封面
echo 可输入文件路径，将想要处理的视频文件拖拽到窗口中
echo 或者输入 mp4 这三个字母，以处理当前目录下的所有 mp4 文件
echo.



:loop
    echo 请输入视频文件路径或 mp4：

    set /p "url="
    set "url=!url:"=!"
    if "!url!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )

    if /i "!url!"=="mp4" (
        for %%f in (*.mp4) do (
            :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
            setlocal disabledelayedexpansion
            set "file_name=%%f"
            setlocal enabledelayedexpansion

            echo 处理: "!file_name!"
            ffmpeg.exe -i "!file_name!" -c copy -map 0:v:0 -map 0:a:0 -map -0:d:2 "temp_!file_name!" -hide_banner -loglevel error
            if !errorlevel! equ 0 (
                del /f /q "!file_name!" >nul
                ren "temp_!file_name!" "!file_name!" >nul
                echo 封面移除成功
            ) else (
                echo 封面移除失败
                if exist "temp_!file_name!" del /f /q "temp_!file_name!" > nul
            )
            echo.
            endlocal
            endlocal
        )
    ) else if exist "!url!" (
        for /f "delims=" %%f in ("!url!") do (
            echo 处理: "%%f"
            ffmpeg.exe -i "%%f" -c copy -map 0:v:0 -map 0:a:0 -map -0:d:2 "%%~dpnf.nocover.mp4" -hide_banner -loglevel error
        )
    ) else (
        echo 错误的输入
    )

    echo.
goto loop
