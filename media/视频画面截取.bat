@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '根据输入的视频和截取时间，自动截取前后各 1 秒内的 10 帧画面，生成 20 张图片' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入视频文件的路径；也可以拖拽单个视频文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对一个文件处理完成后，可继续输入下一个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '截取时间的格式为 HH:MM:SS.XXX，例如 00:01:23.456' -ForegroundColor Green"
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

        REM 解析时间 HH:MM:SS.XXX，计算前 1 秒的起始时间（用 1!var! 技巧避免前导零被当作八进制）
        set /a "t_hh=1!screenshot_time:~0,2! %% 100"
        set /a "t_mm=1!screenshot_time:~3,2! %% 100"
        set /a "t_ss=1!screenshot_time:~6,2! %% 100"
        set /a "t_ms=1!screenshot_time:~9,3! %% 1000"
        set /a "total_ms=t_hh*3600000 + t_mm*60000 + t_ss*1000 + t_ms"
        set /a "prev_ms=total_ms-1000"
        if !prev_ms! lss 0 set "prev_ms=0"

        set /a "p_hh=prev_ms/3600000"
        set /a "p_rem=prev_ms%%3600000"
        set /a "p_mm=p_rem/60000"
        set /a "p_rem=p_rem%%60000"
        set /a "p_ss=p_rem/1000"
        set /a "p_ms=p_rem%%1000"

        set "p_hh=0!p_hh!" & set "p_hh=!p_hh:~-2!"
        set "p_mm=0!p_mm!" & set "p_mm=!p_mm:~-2!"
        set "p_ss=0!p_ss!" & set "p_ss=!p_ss:~-2!"
        set "p_ms=00!p_ms!" & set "p_ms=!p_ms:~-3!"
        set "prev_time=!p_hh!:!p_mm!:!p_ss!.!p_ms!"

        set "t_compact=!t_hh!!t_mm!!t_ss!.!t_ms!"
        set "front_dir=!file_dir!!base_name!_!t_compact!_前"
        set "back_dir=!file_dir!!base_name!_!t_compact!_后"

        echo.
        echo 前 1 秒起始时间：!prev_time!

        echo.
        echo 正在截取前 1 秒的 10 帧画面：
        "!ffmpeg_path!" -y -i "!video_file!" -ss "!prev_time!" -t 1 -vf fps=10 -frames:v 10 "!front_dir!_%%02d.png" >nul 2>&1
        if !errorlevel! neq 0 (
            echo 前 1 秒画面截取失败
        ) else (
            echo 前 1 秒画面截取完成
        )

        echo 正在截取后 1 秒的 10 帧画面：
        "!ffmpeg_path!" -y -i "!video_file!" -ss "!screenshot_time!" -t 1 -vf fps=10 -frames:v 10 "!back_dir!_%%02d.png" >nul 2>&1
        if !errorlevel! neq 0 (
            echo 后 1 秒画面截取失败
        ) else (
            echo 后 1 秒画面截取完成
        )

        echo.
        echo 图片输出目录："!file_dir!"
        echo 图片格式：!base_name!_!t_compact!_前_01.png ~ 前_10.png、后_01.png ~ 后_10.png

        endlocal
        endlocal
    )

    set "video_file="
goto loop

echo.
pause
endlocal & endlocal & exit /b
