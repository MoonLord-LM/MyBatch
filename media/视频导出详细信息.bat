@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 导出视频详细信息为 json
:: 双击运行时，自动递归扫描和处理当前目录下所有的视频文件
:: 拖拽单个视频文件到此脚本上时，则只处理该文件
:: 支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffprobe.exe -version >nul 2>&1
if errorlevel 1 (
    echo 错误: 缺少 ffprobe.exe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    echo 开始扫描
    echo.

    :: 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "file_dir=%%~dpf"
        set "video_file=%%~nxf"
        set "json_file=%%~nxf.json"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"
        if exist "!file_dir!!json_file!" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 已存在: "!file_dir!!json_file!"，跳过此文件
        ) else (
            ffprobe -v error -show_streams -show_format -print_format json "!file_dir!!video_file!" > "!file_dir!!json_file!"
            if errorlevel 1 (
                echo set /a "failed+=1">> "!temp_set!"
                if exist "!file_dir!!json_file!" ( del /f /q "!file_dir!!json_file!" )
                echo 视频解析报错: "!file_dir!!video_file!"
            ) else (
                echo set /a "succeeded+=1">> "!temp_set!"
                echo 保存文件: "!json_file!"
            )
        )
        echo set /a "total+=1">> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    :: 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
) else (
    if not exist "%~1" (
        echo 错误: 文件不存在: "%~1"
        echo.
        pause
        exit /b 1
    )

    setlocal disabledelayedexpansion
    set "file_dir=%~dp1"
    set "video_file=%~nx1"
    set "json_file=%~nx1.json"
    setlocal enabledelayedexpansion

    echo 正在处理: "!video_file!"
    ffprobe -v error -show_streams -show_format -print_format json "!file_dir!!video_file!" > "!file_dir!!json_file!"
    if errorlevel 1 (
        if exist "!file_dir!!json_file!" ( del /f /q "!file_dir!!json_file!" )
        echo 视频解析报错: "!file_dir!!video_file!"
    ) else (
        echo 保存文件: "!json_file!"
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
