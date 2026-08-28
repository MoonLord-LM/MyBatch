@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2" & set "param2_path=%~f2" & set "param2_dir=%~dp2" & set "param2_name=%~n2" & set "param2_ext=%~x2" & set "param2_name_ext=%~nx2"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '保留第 1 个文件的封面、声音、字幕和元数据信息，将第 2 个文件的画面内容，替换到第 1 个文件中，生成新文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入两个视频文件的路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以选中两个视频文件，拖拽到此脚本上，自动识别处理；不支持拖入文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
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

REM 检查 ffprobe 组件
if exist "!script_dir!ffprobe.exe" (
    set "ffprobe_path=!script_dir!ffprobe.exe"
) else if exist "!cd!\ffprobe.exe" (
    set "ffprobe_path=!cd!\ffprobe.exe"
) else if exist "!script_dir!..\ffprobe.exe" (
    set "ffprobe_path=!script_dir!..\ffprobe.exe"
) else if exist "..\ffprobe.exe" (
    set "ffprobe_path=..\ffprobe.exe"
) else (
    set "ffprobe_path=ffprobe"
)
"!ffprobe_path!" -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffprobe 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "video1=!param1!"
set "video2=!param2!"

:input_video1
if "!video1!"=="" (
    echo 请输入要保留声音和元数据信息的文件
    set /p "video1="
    echo.
) else (
    echo 要保留声音和元数据信息的文件："!video1!"
    echo.
)
if "!video1!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_video1
)
set "video1=!video1:"=!"
if exist "!video1!\" (
    echo 不支持文件夹 "!video1!"，请重新输入
    echo.
    set "video1="
    goto input_video1
)
if not exist "!video1!" (
    echo 文件不存在 "!video1!"，请重新输入
    echo.
    set "video1="
    goto input_video1
)

:input_video2
if "!video2!"=="" (
    echo 请输入提供画面内容的文件
    set /p "video2="
    echo.
) else (
    echo 提供画面内容的文件："!video2!"
    echo.
)
if "!video2!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_video2
)
set "video2=!video2:"=!"
if exist "!video2!\" (
    echo 不支持文件夹 "!video2!"，请重新输入
    echo.
    set "video2="
    goto input_video2
)
if not exist "!video2!" (
    echo 文件不存在 "!video2!"，请重新输入
    echo.
    set "video2="
    goto input_video2
)

for %%i in ("!video1!") do (
    setlocal disabledelayedexpansion
    set "file_dir=%%~dpi"
    set "base_name=%%~ni"
    set "file_ext=%%~xi"
    setlocal enabledelayedexpansion

    set "temp_file=!file_dir!!base_name!_temp!file_ext!"
    set "output_file=!file_dir!!base_name!_画面替换!file_ext!"

    echo.
    echo 处理文件："!video1!" & REM
    echo 替换画面："!video2!"

    :: 画面取第 2 个文件的，封面仍然保留第 1 个文件的
    :: 小写 v 匹配所有视频流，大写 V 只匹配除封面之外的纯视频流
    "!ffmpeg_path!" -y -i "!video1!" -i "!video2!" -map 1:V -map 0:v? -map -0:V -map 0:a? -map 0:s? -map_metadata 0 -c copy "!temp_file!"
    if !errorlevel! neq 0 (
        if exist "!temp_file!" ( del /f /q "!temp_file!" )
        echo.
        echo 画面替换失败
    ) else (
        move /y "!temp_file!" "!output_file!" >nul
        echo.
        echo 画面替换成功
        echo 输出文件："!output_file!"
    )

    endlocal
    endlocal
)



echo.
pause
endlocal & endlocal & exit /b
