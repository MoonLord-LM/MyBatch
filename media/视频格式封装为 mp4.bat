@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 视频格式封装为 mp4
:: 双击运行时，自动扫描并处理当前目录下所有非 mp4 格式的视频文件
:: 拖拽单个视频文件到此脚本上时，则只处理该文件



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffmpeg.exe -version >nul 2>&1
if errorlevel 1 (
    echo 错误: 缺少 ffmpeg.exe 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    echo.
    echo 递归扫描并封装为 mp4，格式为 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm...
    echo.
    set "processed=0"
    set "skipped=0"
    set "failed=0"
    for /r %%f in (*.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        call :process_file "%%f"
    )
    echo.
    echo 批量处理完成
    echo 成功: !processed!
    echo 失败: !failed!
    echo 跳过: !skipped!
) else (
    call :process_file "%~1"
)



echo.
pause
exit /b


:process_file
    set "file_path=%~1"
    setlocal disabledelayedexpansion
    set "file_name=%~nx1"
    set "base_name=%~n1"
    set "dir_path=%~dp1"
    setlocal enabledelayedexpansion

    if not "%dir_path%"=="" cd /d "%dir_path%"

    echo 正在处理: !file_name!

    if /i "%~x1"==".mp4" (
        echo 跳过，已经是mp4格式
        if defined processed set /a "skipped+=1"
    ) else (
        set "output_file=!base_name!.mp4"
        if exist "!output_file!" (
            echo 跳过，目标文件已存在: !output_file!
            if defined processed set /a "skipped+=1"
        ) else (
            echo 正在封装为: !output_file!
            ffmpeg -i "!file_name!" -c copy -movflags +faststart "!output_file!" -hide_banner -loglevel error

            if errorlevel 1 (
                echo 封装失败
                if exist "!output_file!" del /f /q "!output_file!" >nul
                if defined processed set /a "failed+=1"
            ) else (
                echo 封装成功
                if defined processed set /a "processed+=1"
            )
        )
    )
    endlocal
    endlocal
goto :eof
