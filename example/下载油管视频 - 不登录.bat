@echo off
setlocal enabledelayedexpansion

:: 支持输入视频链接单个下载，或者输入包含视频链接的 txt 文件路径批量下载
:: 依赖的软件如下
:: https://github.com/yt-dlp/yt-dlp
:: https://github.com/FFmpeg/FFmpeg



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
     --list-formats ^
     --verbose ^
     "!url!"
    set command2=yt-dlp.exe ^
     --concurrent-fragments 20 ^
     -f ""bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"" ^
     --merge-output-format mp4 ^
     --embed-subs ^
     --embed-thumbnail ^
     --embed-metadata ^
     --embed-chapters ^
     --embed-info-json ^
     --verbose ^
     "!url!"
    start "" cmd /c "%command1% & %command2%"
    timeout /t 30
exit /b


:download_video_list
    set "file_path=%~1"

    :: 计算总行数（即总有效链接数）
    set /a total_count=0
    for /f "usebackq tokens=*" %%a in ("!file_path!") do (
        set "line=%%a"
        :: 删除前后空白
        set "line=!line: =!"
        if not "!line!"=="" (
            set /a total_count+=1
        )
    )

    :: 初始化当前进度
    set /a current_count=0
    for /f "usebackq tokens=*" %%a in ("!file_path!") do (
        set "line=%%a"
        :: 删除前后空白
        set "line=!line: =!"
        if not "!line!"=="" (
            set /a current_count+=1
            echo 正在处理第 !current_count!/%total_count% 个链接...
            call :download_video "!line!"
        )
    )
exit /b


:main_loop
    echo 请输入 YouTube 视频链接或包含视频链接的 txt 文件路径
    set /p "input="

    if "!input!"=="" (
        echo 输入不能为空，请重新输入
        goto main_loop
    )

    :: 删除多余的引号
    set "input=!input:"=!"

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


