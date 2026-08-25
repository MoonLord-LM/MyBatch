@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '视频降噪处理，使用 4 种滤镜分别生成不同降噪效果的文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '滤镜使用：nlmeans、hqdn3d、atadenoise、smartblur' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '自动跳过文件名中包含 _smartblur_、_nlmeans_、_hqdn3d_、_atadenoise_ 的已降噪过的视频' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '输出视频使用 h264 格式（高质量 -crf 18 -preset slower）' -ForegroundColor Green"
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



if "!param1!" == "" (
    echo 开始处理当前文件夹："!cd!"
    set "working_dir=!cd!"
    echo.
) else (
    if "!param1:~-1!"=="\" set "param1=!param1:~0,-1!"
    if not exist "!param1!" (
        echo 错误：路径不存在："!param1!"
        echo.
        pause
        endlocal & endlocal & exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 开始处理文件："!param1!"
        set "file_dir=!param1_dir!"
        set "base_name=!param1_name!"

        set "clean_name=!base_name:_smartblur_=!"
        set "clean_name=!clean_name:_nlmeans_=!"
        set "clean_name=!clean_name:_hqdn3d_=!"
        set "clean_name=!clean_name:_atadenoise_=!"
        if not "!clean_name!"=="!base_name!" (
            echo 该文件已是降噪后的视频，跳过
        ) else (
            set "output_file=!file_dir!!base_name!_nlmeans_5_7_15.mp4"
            if exist "!output_file!" (
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!param1!" -vf "nlmeans=s=5:p=7:r=15" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo 降噪成功
                )
            )

            set "output_file=!file_dir!!base_name!_hqdn3d_6_4_8_6.mp4"
            if exist "!output_file!" (
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!param1!" -vf "hqdn3d=6:4:8:6" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo 降噪成功
                )
            )

            set "output_file=!file_dir!!base_name!_atadenoise_8_16_9.mp4"
            if exist "!output_file!" (
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!param1!" -vf "atadenoise=0a=0.08:0b=0.16:1a=0.08:1b=0.16:2a=0.08:2b=0.16:s=9" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo 降噪成功
                )
            )

            set "output_file=!file_dir!!base_name!_smartblur_2_1_5.mp4"
            if exist "!output_file!" (
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!param1!" -vf "smartblur=lr=2:ls=1:lt=5" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo 降噪成功
                )
            )
        )
    )
)

if not "!working_dir!" == "" (
    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "output_exist=0"
    set /a "convert_failed=0"
    set /a "skipped=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!"

        set "clean_name=!base_name:_smartblur_=!"
        set "clean_name=!clean_name:_nlmeans_=!"
        set "clean_name=!clean_name:_hqdn3d_=!"
        set "clean_name=!clean_name:_atadenoise_=!"
        if not "!clean_name!"=="!base_name!" (
            echo 该文件已是降噪后的视频，跳过
            echo set /a "skipped+=1">>"!temp_set!"
        ) else (
            set "output_file=!file_dir!!base_name!_nlmeans_5_7_15.mp4"
            if exist "!output_file!" (
                echo set /a "output_exist+=1">>"!temp_set!"
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!video_file!" -vf "nlmeans=s=5:p=7:r=15" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "convert_failed+=1">>"!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 降噪成功
                )
            )

            set "output_file=!file_dir!!base_name!_hqdn3d_6_4_8_6.mp4"
            if exist "!output_file!" (
                echo set /a "output_exist+=1">>"!temp_set!"
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!video_file!" -vf "hqdn3d=6:4:8:6" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "convert_failed+=1">>"!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 降噪成功
                )
            )

            set "output_file=!file_dir!!base_name!_atadenoise_8_16_9.mp4"
            if exist "!output_file!" (
                echo set /a "output_exist+=1">>"!temp_set!"
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!video_file!" -vf "atadenoise=0a=0.08:0b=0.16:1a=0.08:1b=0.16:2a=0.08:2b=0.16:s=9" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "convert_failed+=1">>"!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 降噪成功
                )
            )

            set "output_file=!file_dir!!base_name!_smartblur_2_1_5.mp4"
            if exist "!output_file!" (
                echo set /a "output_exist+=1">>"!temp_set!"
                echo 已存在："!output_file!"，跳过
            ) else (
                echo 正在生成："!output_file!"
                "!ffmpeg_path!" -i "!video_file!" -vf "smartblur=lr=2:ls=1:lt=5" -c:v libx264 -crf 18 -preset slower -c:a copy "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "convert_failed+=1">>"!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 降噪失败
                ) else (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 降噪成功
                )
            )

            echo set /a "total+=4">>"!temp_set!"
        )
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    set /a "fail_total=convert_failed+output_exist"
    echo 共计：!total! 个，成功：!succeeded! 个，失败：!fail_total! 个 & REM
    echo 其中，降噪成功 !succeeded! 个，降噪失败 !convert_failed! 个，输出文件已存在 !output_exist! 个，跳过已降噪视频 !skipped! 个
)



echo.
pause
endlocal & endlocal & exit /b
