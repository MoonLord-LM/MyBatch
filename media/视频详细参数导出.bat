@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将视频的详细参数信息，导出为同名的 json 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

REM 优先使用脚本所在文件夹中的 ffprobe 组件
set "ffprobe_path=ffprobe"
if exist "%~dp0ffprobe.exe" (
    set "ffprobe_path=%~dp0ffprobe.exe"
) else if exist "!cd!\ffprobe.exe" (
    set "ffprobe_path=!cd!\ffprobe.exe"
)
!ffprobe_path! -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffprobe 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    echo 开始处理当前文件夹："!cd!"
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "json_exist=0"
    set /a "parse_failed=0"
    set "file_path=!cd!"
    set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!"
        set "json_file=!file_dir!!base_name!.json"
        if exist "!json_file!" (
            echo set /a "json_exist+=1">> "!temp_set!"
            echo 已存在："!json_file!"，跳过此文件
        ) else (
            "!ffprobe_path!" -v error -show_streams -show_format -print_format json "!video_file!" > "!json_file!"
            if !errorlevel! neq 0 (
                echo set /a "parse_failed+=1">> "!temp_set!"
                if exist "!json_file!" ( del /f /q "!json_file!" )
                echo 视频解析报错
            ) else (
                echo set /a "succeeded+=1">> "!temp_set!"
                echo 保存文件："!json_file!"
            )
        )
        echo set /a "total+=1">> "!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    set /a "ok_total=succeeded"
    set /a "fail_total=json_exist+parse_failed"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，导出成功 !succeeded! 个，解析报错 !parse_failed! 个，json 文件已存在 !json_exist! 个
) else (
    setlocal disabledelayedexpansion
    set "video_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    setlocal enabledelayedexpansion
    if "!video_file:~-1!"=="\" set "video_file=!video_file:~0,-1!"

    if not exist "!video_file!" (
        echo 错误：文件不存在："!video_file!"
        echo.
        pause
        exit /b 1
    )

    if exist "!video_file!\" (
        echo 开始处理文件夹："!video_file!"
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "json_exist=0"
        set /a "parse_failed=0"
        set "file_path=!video_file!"
        set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "video_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            setlocal enabledelayedexpansion

            echo 处理文件："!video_file!"
            set "json_file=!file_dir!!base_name!.json"
            if exist "!json_file!" (
                echo set /a "json_exist+=1">> "!temp_set!"
                echo 已存在："!json_file!"，跳过此文件
            ) else (
                "!ffprobe_path!" -v error -show_streams -show_format -print_format json "!video_file!" > "!json_file!"
                if !errorlevel! neq 0 (
                    echo set /a "parse_failed+=1">> "!temp_set!"
                    if exist "!json_file!" ( del /f /q "!json_file!" )
                    echo 视频解析报错
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 保存文件："!json_file!"
                )
            )
            echo set /a "total+=1">> "!temp_set!"
            echo.

            endlocal
            endlocal
        )

        REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
        call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

        echo 批量处理完成
        set /a "ok_total=succeeded"
        set /a "fail_total=json_exist+parse_failed"
        echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
        echo 其中，导出成功 !succeeded! 个，解析报错 !parse_failed! 个，json 文件已存在 !json_exist! 个
    ) else (
        echo 开始处理文件："!video_file!"

        set "json_file=!file_dir!!base_name!.json"
        if exist "!json_file!" (
            echo 已存在："!json_file!"，跳过此文件
        ) else (
            "!ffprobe_path!" -v error -show_streams -show_format -print_format json "!video_file!" > "!json_file!"
            if !errorlevel! neq 0 (
                if exist "!json_file!" ( del /f /q "!json_file!" )
                echo 视频解析报错
            ) else (
                echo 保存文件："!json_file!"
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
endlocal
endlocal
exit /b
