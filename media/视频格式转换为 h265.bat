@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 将视频文件转换为 h265 编码的 mp4 格式，拖拽文件到窗口即可处理



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的"以管理员权限运行"，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)



set "convert=-vf yadif -c:v libx265 -preset veryslow -crf 12 -c:a aac -b:a 320k"

:loop
    echo 请将要处理的视频文件拖拽到窗口中

    set /p "input="
    set "input=!input:"=!"
    if "!input!"=="" (
        echo 输入不能为空，请重新输入
        goto loop
    )

    if not exist "!input!" (
        echo 文件不存在: !input!
        goto loop
    )

    for %%a in ("!input!") do set "base_name=%%~na"
    set "output_file=!base_name!.mp4"
    if exist "!output_file!" (
        set "output_file=!base_name!.new.mp4"
    )

    echo 开始处理: !input!
    ffmpeg.exe -i "!input!" !convert! -map_metadata 0 -movflags +faststart "!output_file!"
    if errorlevel 1 (
        echo 处理失败: !input!
    ) else (
        echo 处理完成: !output_file!
    )
    echo.
goto loop



echo.
pause
exit /b

