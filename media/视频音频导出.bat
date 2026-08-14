@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '导出视频音频，根据编码自动选择格式（优先无损复制）' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有的 mp4 视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
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

ffprobe -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误: 缺少 ffprobe 组件
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
    for /r %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!video_file!"
        set "audio_codec="
        for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
            set "audio_codec=%%a"
        )

        if "!audio_codec!"=="" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 无音频
        ) else (
            set "audio_ext=m4a"
            set "audio_enc=-c:a aac -b:a 320k"
            if /i "!audio_codec!"=="aac" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="eac3" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="alac" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="mp3" ( set "audio_ext=mp3" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="flac" ( set "audio_ext=flac" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="pcm_dvd" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s16be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s16le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u16be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u16le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s24be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s24le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u24be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u24le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s32be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s32le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u32be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u32le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )

            REM 跳过封面的判断复用
            set "audio_file=!file_dir!!base_name!.!audio_ext!"
            if exist "!audio_file!" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 已存在: "!audio_file!"，跳过此文件
            ) else (
                ffmpeg -i "!video_file!" -vn !audio_enc! "!audio_file!"
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    if exist "!audio_file!" ( del /f /q "!audio_file!" )
                    echo 导出失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 保存文件: "!audio_file!"
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
        for /r "!video_file!" %%f in (*.mp4 *.mkv *.ts *.avi *.wmv *.flv *.rmvb *.rm *.vob *.mpg *.mpeg *.3gp *.m4v *.f4v *.mov *.webm) do (
            setlocal disabledelayedexpansion
            set "video_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!video_file!"
            set "audio_codec="
            for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "audio_codec=%%a"
            )

            if "!audio_codec!"=="" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 无音频
            ) else (
                set "audio_ext=m4a"
                set "audio_enc=-c:a aac -b:a 320k"
                if /i "!audio_codec!"=="aac" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
                if /i "!audio_codec!"=="eac3" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
                if /i "!audio_codec!"=="alac" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
                if /i "!audio_codec!"=="mp3" ( set "audio_ext=mp3" & set "audio_enc=-c:a copy" )
                if /i "!audio_codec!"=="flac" ( set "audio_ext=flac" & set "audio_enc=-c:a copy" )
                if /i "!audio_codec!"=="pcm_dvd" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_s16be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_s16le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_u16be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_u16le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_s24be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_s24le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_u24be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_u24le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_s32be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_s32le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_u32be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
                if /i "!audio_codec!"=="pcm_u32le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )

                set "audio_file=!file_dir!!base_name!.!audio_ext!"
                if exist "!audio_file!" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 已存在: "!audio_file!"，跳过此文件
                ) else (
                    ffmpeg -i "!video_file!" -vn !audio_enc! "!audio_file!"
                    if !errorlevel! neq 0 (
                        echo set /a "failed+=1">> "!temp_set!"
                        if exist "!audio_file!" ( del /f /q "!audio_file!" )
                        echo 导出失败
                    ) else (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 保存文件: "!audio_file!"
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

        set "audio_codec="
        for /f "delims=" %%a in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
            set "audio_codec=%%a"
        )

        if "!audio_codec!"=="" (
            echo 无音频
        ) else (
            set "audio_ext=m4a"
            set "audio_enc=-c:a aac -b:a 320k"
            if /i "!audio_codec!"=="aac" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="mp3" ( set "audio_ext=mp3" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="alac" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="flac" ( set "audio_ext=flac" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="eac3" ( set "audio_ext=m4a" & set "audio_enc=-c:a copy" )
            if /i "!audio_codec!"=="pcm_dvd" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s16be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s16le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u16be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u16le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s24be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s24le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u24be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u24le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s32be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_s32le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u32be" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )
            if /i "!audio_codec!"=="pcm_u32le" ( set "audio_ext=flac" & set "audio_enc=-c:a flac -compression_level 8" )

            set "audio_file=!file_dir!!base_name!.!audio_ext!"
            if exist "!audio_file!" (
                echo 已存在: "!audio_file!"，跳过此文件
            ) else (
                ffmpeg -i "!video_file!" -vn !audio_enc! "!audio_file!"
                if !errorlevel! neq 0 (
                    if exist "!audio_file!" ( del /f /q "!audio_file!" )
                    echo 导出失败
                ) else (
                    echo 保存文件: "!audio_file!"
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
