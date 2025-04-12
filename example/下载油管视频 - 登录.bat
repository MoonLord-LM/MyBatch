@echo off
setlocal enabledelayedexpansion

:: 支持输入视频链接单个下载，或者输入包含视频链接的 txt 文件路径批量下载
:: 依赖的软件如下
:: https://github.com/yt-dlp/yt-dlp
:: https://github.com/FFmpeg/FFmpeg
:: https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc



call :init
goto :main_loop


:init
    yt-dlp --update
    yt-dlp --rm-cache-dir
exit /b


:download_video
    set "url=%~1"
    
    :: 删除 & 和后面的内容
    if "!url!" neq "!url:&=!" (
        for /f "tokens=1 delims=&" %%i in ("!url!") do set "url=%%i"
    )

    echo 在新窗口中下载: "!url!"
    set command1=yt-dlp.exe ^
     --cookies ""www.youtube.com_cookies.txt"" ^
     --list-formats ^
     --verbose ^
     "!url!"
    set command2=yt-dlp.exe ^
     --cookies ""www.youtube.com_cookies.txt"" ^
     --concurrent-fragments 20 ^
     -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ^
     --merge-output-format mp4 ^
     --embed-subs ^
     --embed-thumbnail ^
     --embed-metadata ^
     --embed-chapters ^
     --embed-info-json ^
     --verbose ^
     "!url!"
    start "" cmd /c "%command1% & %command2%"
    timeout /t 10
exit /b


:download_video_list
    set "file_path=%~1"
    for /f "tokens=*" %%a in (!file_path!) do (
        call :download_video "%%a"
    )
exit /b


:main_loop
    echo 请输入 YouTube 视频链接或包含视频链接的 txt 文件路径
    set /p "input="

    if "!input!"=="" (
        echo 输入不能为空，请重新输入
        goto main_loop
    )

    :: 检查是否是有效的文件路径
    if exist "!input!" (
        call :download_video_list "!input!"
    ) else (
        :: 如果不是文件路径，则视为URL
        echo "!input!" | findstr /C:"https://www.youtube.com/watch?v=" >nul
        if !errorlevel! == 1 (
            echo 输入的不是有效的 YouTube 链接，请重新输入
            goto main_loop
        )
        call :download_video "!input!"
    )
goto main_loop


