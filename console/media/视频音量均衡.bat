@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '视频音量均衡，把过轻的音量提升、过响的音量压低' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '只重新编码音频，画面流直接复制，用 EBU R128 两遍响度归一化，把音量统一到 -16 LUFS' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '自动跳过无音轨、以及文件名中包含 _音量均衡 的已均衡过的视频' -ForegroundColor Green"
echo.



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
    echo 错误：缺少 ffmpeg 组件 & REM
    echo 请从 https://ffmpeg.org/download.html 下载，然后把 ffmpeg.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
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
    echo 错误：缺少 ffprobe 组件 & REM
    echo 请从 https://ffmpeg.org/download.html 下载，然后把 ffprobe.exe 放到脚本所在文件夹 & REM
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



REM 响度归一化目标
set "loudnorm_base=I=-16:TP=-1.5:LRA=11"

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
        exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 开始处理文件："!param1!"
        set "video_file=!param1!"
        set "file_dir=!param1_dir!"
        set "base_name=!param1_name!"
        set "file_ext=!param1_ext!"

        set "clean_name=!base_name:_音量均衡=!"
        if not "!clean_name!"=="!base_name!" (
            echo 该文件已是音量均衡后的视频，跳过
        ) else (
            REM 检测音轨
            set "audio_codec="
            for /f "delims=" %%a in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "& $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"
            ') do (
                set "audio_codec=%%a"
            )

            if "!audio_codec!"=="" (
                echo 无音频
            ) else (
                set "output_file=!file_dir!!base_name!_音量均衡!file_ext!"
                if exist "!output_file!" (
                    echo 已存在："!output_file!"，跳过此文件
                ) else (
                    echo 正在分析音量："!video_file!"
                    set "loudnorm_measured="
                    for /f "delims=" %%m in ('
                        powershell -NoProfile -Command ^
                            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                            "$log = & $env:ffmpeg_path -i $env:video_file -map 0:a:0 -af ('loudnorm=' + $env:loudnorm_base + ':print_format=json') -f null - 2>&1 | Out-String;" ^
                            "$matched = [regex]::Match($log, '\{[^}]*\}');" ^
                            "if ($matched.Success) { $stats = $matched.Value | ConvertFrom-Json;" ^
                            "Write-Output ('measured_I={0}:measured_TP={1}:measured_LRA={2}:measured_thresh={3}:offset={4}:linear=true' -f $stats.input_i, $stats.input_tp, $stats.input_lra, $stats.input_thresh, $stats.target_offset); }"
                    ') do (
                        set "loudnorm_measured=%%m"
                    )

                    if "!loudnorm_measured!"=="" (
                        echo 音量分析失败
                    ) else (
                        echo 正在均衡为："!output_file!"
                        set "faststart_args="
                        for %%e in (.mp4 .3gp .m4v .f4v .mov .m4a) do if /i "!file_ext!"=="%%e" set "faststart_args=-movflags +faststart"
                        "!ffmpeg_path!" -i "!video_file!" -af "loudnorm=!loudnorm_base!:!loudnorm_measured!" -c:v copy -c:a flac -compression_level 8 !faststart_args! "!output_file!"
                        if !errorlevel! neq 0 (
                            if exist "!output_file!" ( del /f /q "!output_file!" )
                            echo 均衡失败
                        ) else (
                            echo 均衡成功
                        )
                    )
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
    set /a "no_audio=0"
    set /a "output_exist=0"
    set /a "analyze_failed=0"
    set /a "balance_failed=0"
    set /a "skipped=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('
        powershell -NoProfile -Command ^
            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
            "Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"
    ') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!"

        set "clean_name=!base_name:_音量均衡=!"
        if not "!clean_name!"=="!base_name!" (
            echo set /a "skipped+=1">>"!temp_set!"
            echo 该文件已是音量均衡后的视频，跳过
        ) else (
            REM 检测音轨
            set "audio_codec="
            for /f "delims=" %%a in ('
                powershell -NoProfile -Command ^
                    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                    "& $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"
            ') do (
                set "audio_codec=%%a"
            )

            if "!audio_codec!"=="" (
                echo set /a "no_audio+=1">>"!temp_set!"
                echo 无音频
            ) else (
                set "output_file=!file_dir!!base_name!_音量均衡!file_ext!"
                if exist "!output_file!" (
                    echo set /a "output_exist+=1">>"!temp_set!"
                    echo 已存在："!output_file!"，跳过此文件
                ) else (
                    echo 正在分析音量："!video_file!"
                    set "loudnorm_measured="
                    for /f "delims=" %%m in ('
                        powershell -NoProfile -Command ^
                            "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                            "$log = & $env:ffmpeg_path -i $env:video_file -map 0:a:0 -af ('loudnorm=' + $env:loudnorm_base + ':print_format=json') -f null - 2>&1 | Out-String;" ^
                            "$matched = [regex]::Match($log, '\{[^}]*\}');" ^
                            "if ($matched.Success) { $stats = $matched.Value | ConvertFrom-Json;" ^
                            "Write-Output ('measured_I={0}:measured_TP={1}:measured_LRA={2}:measured_thresh={3}:offset={4}:linear=true' -f $stats.input_i, $stats.input_tp, $stats.input_lra, $stats.input_thresh, $stats.target_offset); }"
                    ') do (
                        set "loudnorm_measured=%%m"
                    )

                    if "!loudnorm_measured!"=="" (
                        echo set /a "analyze_failed+=1">>"!temp_set!"
                        echo 音量分析失败
                    ) else (
                        echo 正在均衡为："!output_file!"
                        set "faststart_args="
                        for %%e in (.mp4 .3gp .m4v .f4v .mov .m4a) do if /i "!file_ext!"=="%%e" set "faststart_args=-movflags +faststart"
                        "!ffmpeg_path!" -i "!video_file!" -af "loudnorm=!loudnorm_base!:!loudnorm_measured!" -c:v copy -c:a flac -compression_level 8 !faststart_args! "!output_file!"
                        if !errorlevel! neq 0 (
                            echo set /a "balance_failed+=1">>"!temp_set!"
                            if exist "!output_file!" ( del /f /q "!output_file!" )
                            echo 均衡失败
                        ) else (
                            echo set /a "succeeded+=1">>"!temp_set!"
                            echo 均衡成功
                        )
                    )
                )
            )
        )
        echo set /a "total+=1">>"!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo 批量处理完成
    set /a "ok_total=succeeded"
    set /a "fail_total=no_audio+output_exist+analyze_failed+balance_failed"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，均衡成功 !succeeded! 个，均衡失败 !balance_failed! 个，音量分析失败 !analyze_failed! 个，无音频 !no_audio! 个，输出文件已存在 !output_exist! 个，跳过已均衡视频 !skipped! 个
)



echo.
pause
exit /b
