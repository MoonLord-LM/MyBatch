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
    if "!url!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )

    if /i "!url!"=="mp4" (
        for %%f in (*.mp4) do (
            echo 处理: %%f
            ffmpeg.exe -i "%%f" -c copy -map 0 -map -0:t "temp_%%~nxf" -hide_banner -loglevel error
            if !errorlevel! equ 0 (
                del /f /q "%%f" >nul
                ren "temp_%%~nxf" "%%f" >nul
                echo 封面移除成功
            ) else (
                echo 封面移除失败
                if exist "temp_%%~nxf" del /f /q "temp_%%~nxf" > nul
            )
            echo.
        )
    ) else if exist "!url!" (
        echo 处理: "!url!"
        for %%f in ("!url!") do (
            ffmpeg.exe -i "%%f" -c copy -map 0 -map -0:t "%%~dpnf.nocover.mp4" -hide_banner -loglevel error
        )
    ) else (
        echo 错误的输入
    )

    echo.
goto loop
