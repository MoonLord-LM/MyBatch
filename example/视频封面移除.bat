@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 依赖的软件如下
:: https://github.com/FFmpeg/FFmpeg

echo.
echo 本脚本用于移除视频封面
echo. >nul
echo 可输入文件路径，将想要处理的视频文件拖拽到窗口中
echo. >nul
echo 或者输入 mp4 这三个字母，以处理当前目录下的所有 mp4 文件
echo.



:loop
    echo 请输入视频文件路径或 mp4：

    set /p "path="
    set "path=!path:"=!"
    if "!path!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )

    if /i "!path!"=="mp4" (
        for %%f in (*.mp4) do (
            call :process_file "%%~f"
        )
    ) else if exist "!path!" (
        for %%f in ("!path!") do (
            call :process_file "%%~f"
        )
    ) else (
        echo 错误的输入
    )

    echo.
goto loop



:process_file
    :: 必须在 disabledelayedexpansion 范围内，才能获取完整的包含 ^ 和 ! 符号的文件名
    setlocal disabledelayedexpansion
    set "file_path=%~1"
    set "dir_path=%~dp1"
    set "base_name=%~n1"
    set "ext_name=%~x1"
    setlocal enabledelayedexpansion

    echo 处理: "!file_path!"

    :: 先检查是否存在封面
    set "has_cover=0"
    for /f "delims=" %%c in ('ffprobe.exe -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!file_path!" 2^>nul') do (
        if "%%c"=="1" (
            set "has_cover=1"
        )
    )

    if "!has_cover!"=="0" (
        echo 无封面，跳过："!file_path!"
    ) else (
        set "backup_path=!dir_path!!base_name!.bak!ext_name!"
        move /y "!file_path!" "!backup_path!" >nul
        if !errorlevel! equ 0 (
            ffmpeg.exe -i "!backup_path!" -c copy -map 0:v:0 -map 0:a:0 -map -0:d:2 "!file_path!" -hide_banner -loglevel error
            if !errorlevel! equ 0 (
                :: del /f /q "!backup_path!" >nul
                echo 封面移除成功："!file_path!"
            ) else (
                if not exist "!file_path!" (
                    move /y "!backup_path!" "!file_path!" >nul
                )
                echo 封面移除失败："!file_path!"
            )
        ) else (
            echo 备份失败，跳过："!file_path!"
        )
    )

    echo.
    endlocal
    endlocal
goto :eof
