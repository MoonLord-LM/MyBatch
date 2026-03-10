@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 导出视频详细信息为 json
:: 双击运行时，自动扫描并处理当前目录下所有格式的视频文件
:: 拖拽单个视频文件到此脚本上，则只处理该文件



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
    echo.
    echo 未检测到输入文件，将自动扫描并处理当前目录下的所有视频文件。
    echo.
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        call :process_file "%%f"
    )
    echo.
    echo 批量处理完成
) else (
    call :process_file "%~1"
)



echo.
pause
exit /b


:process_file
    set "file_path=%~1"
    if not exist "%file_path%" goto :eof

    setlocal disabledelayedexpansion
    set "file_name=%~nx1"
    set "file_dir_path=%~dp1"
    set "file_base_name=%~n1"
    setlocal enabledelayedexpansion

    if not "!file_dir_path!"=="" cd /d "!file_dir_path!"

    echo 正在处理: !file_name!
    
    set "output_file=!file_base_name!.json"
    ffprobe -v error -show_streams -show_format -print_format json "!file_name!" > "!output_file!"
    echo 详细信息已保存到: !output_file!

    endlocal
    endlocal
goto :eof
