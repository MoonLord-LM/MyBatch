@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '根据输入的视频、开始时间、结束时间，对视频做无损的切片截取' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入视频文件的路径；也可以拖拽单个视频文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对一个文件处理完成后，可继续输入下一个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '视频如果是 ts 格式，会自动转为同名的 mp4 后再截取，避免音画不同步问题' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '开始和结束时间的格式为 HH:MM:SS.XXX，例如 00:01:23.456' -ForegroundColor Green"
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
    set "begin_time="
    set "end_time="

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

    :input_begin_time
    echo.
    echo 请输入开始时间（格式: HH:MM:SS.XXX）：
    set /p "begin_time="
    if "!begin_time!"=="" (
        echo 开始时间不能为空
        goto input_begin_time
    )

    :input_end_time
    echo 请输入结束时间（格式: HH:MM:SS.XXX）：
    set /p "end_time="
    if "!end_time!"=="" (
        echo 结束时间不能为空
        goto input_end_time
    )

    for %%i in ("!video_file!") do (
        setlocal disabledelayedexpansion
        set "file_dir=%%~dpi"
        set "base_name=%%~ni"
        set "file_ext=%%~xi"
        setlocal enabledelayedexpansion

        echo.
        echo 处理文件："!video_file!" & REM
        echo 截取时间：!begin_time! - !end_time!

        set "work_file=!video_file!"
        if /i "!file_ext!"==".ts" (
            set "work_file=!file_dir!!base_name!.mp4"
            echo 检测到 ts 格式，先转为同名 mp4："!work_file!"
            "!ffmpeg_path!" -y -i "!video_file!" -c copy "!work_file!" >nul 2>&1
            if !errorlevel! neq 0 (
                echo.
                echo ts 转 mp4 失败，程序退出
                echo.
                pause
                endlocal & endlocal & exit /b 1
            )
            echo ts 转 mp4 完成
        )

        set "output_file=!file_dir!!base_name!_!begin_time::=!-!end_time::=!.mp4"
        if exist "!output_file!" (
            echo 已存在："!output_file!"，跳过
        ) else (
            echo 正在截取："!output_file!"
            "!ffmpeg_path!" -ss "!begin_time!" -to "!end_time!" -i "!work_file!" -c copy "!output_file!" -movflags +faststart -y
            if !errorlevel! neq 0 (
                if exist "!output_file!" ( del /f /q "!output_file!" )
                echo.
                echo 视频截取失败
            ) else (
                echo.
                echo 视频截取成功
                echo 输出文件："!output_file!"
            )
        )

        endlocal
        endlocal
    )

    set "video_file="
goto loop

echo.
pause
endlocal & endlocal & exit /b
