@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '视频格式封装为 mkv' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有非 mkv 格式的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
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

        if /i "!param1_ext!"==".mkv" (
            echo 跳过，已经是 mkv 格式
        ) else (
            set "output_file=!file_dir!!base_name!.mkv"
            if exist "!output_file!" (
                echo 已存在："!output_file!"，跳过此文件
            ) else (
                echo 正在封装为："!output_file!"

                REM 检测音频编码格式
                for /f "tokens=*" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:param1 2>$null"') do (
                    set "audio_codec=%%a"
                )

                REM 不支持的音频编码列表（含 RealMedia cook、DVD PCM 等）
                set "unsupported_codecs=cook pcm_dvd pcm_s16be pcm_s16le pcm_u16be pcm_u16le pcm_s24be pcm_s24le pcm_u24be pcm_u24le pcm_s32be pcm_s32le pcm_u32be pcm_u32le"
                set "need_convert=0"
                for %%c in (!unsupported_codecs!) do (
                    if /i "!audio_codec!"=="%%c" set "need_convert=1"
                )

                if "!need_convert!"=="1" (
                    echo 检测到不支持的音频编码：!audio_codec!，正在转换为 FLAC 格式...
                    "!ffmpeg_path!" -i "!param1!" -c:v copy -c:a flac -compression_level 8 "!output_file!"
                    if !errorlevel! neq 0 (
                        if exist "!output_file!" ( del /f /q "!output_file!" )
                        echo 封装失败
                    ) else (
                        echo 封装成功（音频已转换）
                    )
                ) else (
                    "!ffmpeg_path!" -i "!param1!" -c copy "!output_file!"
                    if !errorlevel! neq 0 (
                        if exist "!output_file!" ( del /f /q "!output_file!" )
                        echo 封装失败
                    ) else (
                        echo 封装成功
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
    set /a "output_exist=0"
    set /a "mux_failed=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(mp4|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!"
        set "output_file=!file_dir!!base_name!.mkv"
        if exist "!output_file!" (
            echo set /a "output_exist+=1">>"!temp_set!"
            echo 已存在："!output_file!"，跳过此文件
        ) else (
            echo 正在封装为："!output_file!"

            REM 检测音频编码格式
            for /f "tokens=*" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "audio_codec=%%a"
            )

            REM 不支持的音频编码列表（含 RealMedia cook、DVD PCM 等）
            set "unsupported_codecs=cook pcm_dvd pcm_s16be pcm_s16le pcm_u16be pcm_u16le pcm_s24be pcm_s24le pcm_u24be pcm_u24le pcm_s32be pcm_s32le pcm_u32be pcm_u32le"
            set "need_convert=0"
            for %%c in (!unsupported_codecs!) do (
                if /i "!audio_codec!"=="%%c" set "need_convert=1"
            )

            if "!need_convert!"=="1" (
                echo 检测到不支持的音频编码：!audio_codec!，正在转换为 FLAC 格式...
                "!ffmpeg_path!" -i "!video_file!" -c:v copy -c:a flac -compression_level 8 "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "mux_failed+=1">>"!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 封装失败
                ) else (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 封装成功（音频已转换）
                )
            ) else (
                "!ffmpeg_path!" -i "!video_file!" -c copy "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "mux_failed+=1">>"!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 封装失败
                ) else (
                    echo set /a "succeeded+=1">>"!temp_set!"
                    echo 封装成功
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
    set /a "fail_total=mux_failed+output_exist"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，封装成功 !succeeded! 个，封装失败 !mux_failed! 个，输出文件已存在 !output_exist! 个
)



echo.
pause
endlocal & endlocal & exit /b
