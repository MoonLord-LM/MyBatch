@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '根据输入的视频和截取时间，自动截取 20 帧连续画面' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入视频文件的路径；也可以拖拽单个视频文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对一个文件处理完成后，可继续输入下一个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '视频如果是 ts 格式，会自动转为同名的 mp4 后再截取，避免音画不同步问题' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '截取时间的格式为 HH:MM:SS 或 HH:MM:SS.XXX，例如 00:01:23.456' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 ffmpeg 组件
if exist "!script_dir!ffmpeg.exe" (
    set "ffmpeg_path=!script_dir!ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
) else if exist "!script_dir!..\ffmpeg.exe" (
    set "ffmpeg_path=!script_dir!..\ffmpeg.exe"
) else if exist "..\ffmpeg.exe" (
    set "ffmpeg_path=..\ffmpeg.exe"
) else (
    set "ffmpeg_path=ffmpeg"
)
"!ffmpeg_path!" -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "video_file=!param1!"

:loop
    set "screenshot_time="

    :input_file
    if "!video_file!"=="" (
        echo.
        echo 请输入要处理的视频文件：
        set /p "video_file="
    )
    if "!video_file!"=="" (
        echo 输入不能为空，请重新输入
        goto input_file
    )
    set "video_file=!video_file:"=!"
    if exist "!video_file!\" (
        echo 不支持文件夹 "!video_file!"，请重新输入
        set "video_file="
        goto input_file
    )
    if not exist "!video_file!" (
        echo 文件不存在 "!video_file!"，请重新输入
        set "video_file="
        goto input_file
    )

    echo 开始处理文件："!video_file!"
    echo.

    :input_screenshot_time
    echo.
    echo 请输入截取时间（格式: HH:MM:SS.XXX）：
    set /p "screenshot_time="
    if "!screenshot_time!"=="" (
        echo 截取时间不能为空
        goto input_screenshot_time
    )

    for %%i in ("!video_file!") do (
        setlocal disabledelayedexpansion
        set "file_dir=%%~dpi"
        set "base_name=%%~ni"
        set "file_ext=%%~xi"
        setlocal enabledelayedexpansion

        echo.
        echo 处理文件："!video_file!" & REM
        echo 截取时间：!screenshot_time!

        set "screenshot_time_std=!screenshot_time!"
        if not "!screenshot_time_std:~8,1!"=="." set "screenshot_time_std=!screenshot_time_std!.000"

        set "t_compact=!screenshot_time_std:~0,2!!screenshot_time_std:~3,2!!screenshot_time_std:~6,2!.!screenshot_time_std:~9,3!"
        set "out_dir=!file_dir!!base_name!_!t_compact!"

        echo.
        echo 正在截取目标时间之后 2 秒内的 20 帧画面：
        "!ffmpeg_path!" -y -i "!video_file!" -ss "!screenshot_time_std!" -t 2 -vf "fps=10" -frames:v 20 "!out_dir!_%%02d.png" >nul 2>&1
        if !errorlevel! neq 0 (
            echo 截图失败
        ) else (
            echo.
            echo 截图完成，共 20 张：!out_dir!_01.png ~ !out_dir!_20.png
        )

        endlocal
        endlocal
    )

    set "video_file="
goto loop



echo.
pause
endlocal & endlocal & exit /b
