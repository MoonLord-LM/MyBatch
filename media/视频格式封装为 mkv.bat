@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '视频格式封装为 mkv' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有非 mkv 格式的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

ffmpeg -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误: 缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    echo 开始扫描
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    for /r %%f in (*.mp4 *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"
        set "output_file=!file_dir!!base_name!.mkv"
        if exist "!output_file!" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 已存在: "!output_file!"，跳过此文件
        ) else (
            echo 正在封装为: "!output_file!"

            REM 检测音频编码格式
            for /f "tokens=*" %%a in ('ffprobe -v error -select_streams a -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do set "audio_codec=%%a"

            REM 不支持的音频编码列表（含 RealMedia cook、DVD PCM 等）
            set "unsupported_codecs=cook pcm_dvd pcm_s16be pcm_s16le pcm_u16be pcm_u16le pcm_s24be pcm_s24le pcm_u24be pcm_u24le pcm_s32be pcm_s32le pcm_u32be pcm_u32le"
            set "need_convert=0"
            for %%c in (!unsupported_codecs!) do (
                if /i "!audio_codec!"=="%%c" set "need_convert=1"
            )

            if "!need_convert!"=="1" (
                echo 检测到不支持的音频编码: !audio_codec!，正在转换为 FLAC 格式...
                ffmpeg -i "!video_file!" -c:v copy -c:a flac -compression_level 8 "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 封装失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 封装成功（音频已转换）
                )
            ) else (
                ffmpeg -i "!video_file!" -c copy "!output_file!"
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    if exist "!output_file!" ( del /f /q "!output_file!" )
                    echo 封装失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 封装成功
                )
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
    echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
) else (
    setlocal disabledelayedexpansion
    set "video_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    setlocal enabledelayedexpansion

    if not exist "!video_file!" (
        echo 错误: 文件不存在: "!video_file!"
        echo.
        pause
        exit /b 1
    )

    if exist "!video_file!\" (
        echo 开始处理文件夹: "!video_file!"
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "skipped=0"
        set /a "failed=0"
        for /r "!video_file!" %%f in (*.mp4 *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
            setlocal disabledelayedexpansion
            set "video_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!video_file!"
            set "output_file=!file_dir!!base_name!.mkv"
            if exist "!output_file!" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 已存在: "!output_file!"，跳过此文件
            ) else (
                echo 正在封装为: "!output_file!"

                REM 检测音频编码格式
                for /f "tokens=*" %%a in ('ffprobe -v error -select_streams a -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do set "audio_codec=%%a"

                REM 不支持的音频编码列表（含 RealMedia cook、DVD PCM 等）
                set "unsupported_codecs=cook pcm_dvd pcm_s16be pcm_s16le pcm_u16be pcm_u16le pcm_s24be pcm_s24le pcm_u24be pcm_u24le pcm_s32be pcm_s32le pcm_u32be pcm_u32le"
                set "need_convert=0"
                for %%c in (!unsupported_codecs!) do (
                    if /i "!audio_codec!"=="%%c" set "need_convert=1"
                )

                if "!need_convert!"=="1" (
                    echo 检测到不支持的音频编码: !audio_codec!，正在转换为 FLAC 格式...
                    ffmpeg -i "!video_file!" -c:v copy -c:a flac -compression_level 8 "!output_file!"
                    if !errorlevel! neq 0 (
                        echo set /a "failed+=1">> "!temp_set!"
                        if exist "!output_file!" ( del /f /q "!output_file!" )
                        echo 封装失败
                    ) else (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 封装成功（音频已转换）
                    )
                ) else (
                    ffmpeg -i "!video_file!" -c copy "!output_file!"
                    if !errorlevel! neq 0 (
                        echo set /a "failed+=1">> "!temp_set!"
                        if exist "!output_file!" ( del /f /q "!output_file!" )
                        echo 封装失败
                    ) else (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 封装成功
                    )
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
        echo 共计: !total! 个，成功: !succeeded! 个，跳过: !skipped! 个，失败: !failed! 个
    ) else (
        echo 开始处理文件: "!video_file!"

        if /i "%~x1"==".mkv" (
            echo 跳过，已经是 mkv 格式
        ) else (
            set "output_file=!file_dir!!base_name!.mkv"
            if exist "!output_file!" (
                echo 已存在: "!output_file!"，跳过此文件
            ) else (
                echo 正在封装为: "!output_file!"

                REM 检测音频编码格式
                for /f "tokens=*" %%a in ('ffprobe -v error -select_streams a -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do set "audio_codec=%%a"

                REM 不支持的音频编码列表（含 RealMedia cook、DVD PCM 等）
                set "unsupported_codecs=cook pcm_dvd pcm_s16be pcm_s16le pcm_u16be pcm_u16le pcm_s24be pcm_s24le pcm_u24be pcm_u24le pcm_s32be pcm_s32le pcm_u32be pcm_u32le"
                set "need_convert=0"
                for %%c in (!unsupported_codecs!) do (
                    if /i "!audio_codec!"=="%%c" set "need_convert=1"
                )

                if "!need_convert!"=="1" (
                    echo 检测到不支持的音频编码: !audio_codec!，正在转换为 FLAC 格式...
                    ffmpeg -i "!video_file!" -c:v copy -c:a flac -compression_level 8 "!output_file!"
                    if !errorlevel! neq 0 (
                        if exist "!output_file!" ( del /f /q "!output_file!" )
                        echo 封装失败
                    ) else (
                        echo 封装成功（音频已转换）
                    )
                ) else (
                    ffmpeg -i "!video_file!" -c copy "!output_file!"
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

    endlocal
    endlocal
)



echo.
pause
exit /b
