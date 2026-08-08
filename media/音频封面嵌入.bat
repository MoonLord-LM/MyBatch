@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将与音频文件名同名的图片文件，设置为音频的封面' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有的音频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个音频文件到此脚本上时，则只处理该文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 flac mp3' -ForegroundColor Green"
echo.



if /i "%cd%"=="%SystemRoot%\System32" (
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
    for /r %%f in (*.flac *.mp3) do (
        setlocal disabledelayedexpansion
        set "audio_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!audio_file!"
        set "has_cover=0"
        for /f "delims=" %%c in ('ffprobe -v error -select_streams v -show_entries stream^=codec_name -of csv^=p^=0 "!audio_file!" 2^>nul') do (
            set "has_cover=1"
        )

        if "!has_cover!"=="1" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 已有封面，跳过
        ) else (
            set "cover_file="
            if exist "!file_dir!!base_name!.png" (
                set "cover_file=!file_dir!!base_name!.png"
            ) else if exist "!file_dir!!base_name!.jpg" (
                set "cover_file=!file_dir!!base_name!.jpg"
            )

            if not "!cover_file!"=="" (
                echo 找到封面: "!cover_file!"
                set "temp_audio_file=!file_dir!!base_name!_temp!file_ext!"
                if /i "!file_ext!"==".flac" (
                    ffmpeg -i "!audio_file!" -i "!cover_file!" -map 0:0 -map 1:0 -c:a copy -c:v mjpeg -disposition:v:0 attached_pic -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "!temp_audio_file!"
                ) else (
                    ffmpeg -i "!audio_file!" -i "!cover_file!" -map 0:0 -map 1:0 -c copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v:1 attached_pic "!temp_audio_file!"
                )
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    if exist "!temp_audio_file!" ( del /f /q "!temp_audio_file!" )
                    echo 设置失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('!audio_file!', 'OnlyErrorDialogs', 'SendToRecycleBin')"
                    move /y "!temp_audio_file!" "!audio_file!" >nul
                    echo 设置成功
                )
            ) else (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 未找到封面图片，跳过
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
    set "audio_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    set "file_ext=%~x1"
    setlocal enabledelayedexpansion

    if not exist "!audio_file!" (
        echo 错误: 文件不存在: "!audio_file!"
        echo.
        pause
        exit /b 1
    )

    echo 正在处理: "!audio_file!"
    set "has_cover=0"
    for /f "delims=" %%c in ('ffprobe -v error -select_streams v -show_entries stream^=codec_name -of csv^=p^=0 "!audio_file!" 2^>nul') do (
        set "has_cover=1"
    )

    if "!has_cover!"=="1" (
        echo 已有封面，跳过
    ) else (
        set "cover_file="
        if exist "!file_dir!!base_name!.png" (
            set "cover_file=!file_dir!!base_name!.png"
        ) else if exist "!file_dir!!base_name!.jpg" (
            set "cover_file=!file_dir!!base_name!.jpg"
        )

        if not "!cover_file!"=="" (
            echo 找到封面: "!cover_file!"
            set "temp_audio_file=!file_dir!!base_name!_temp!file_ext!"
            if /i "!file_ext!"==".flac" (
                ffmpeg -i "!audio_file!" -i "!cover_file!" -map 0:0 -map 1:0 -c:a copy -c:v mjpeg -disposition:v:0 attached_pic -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "!temp_audio_file!"
            ) else (
                ffmpeg -i "!audio_file!" -i "!cover_file!" -map 0:0 -map 1:0 -c copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v:1 attached_pic "!temp_audio_file!"
            )
            if !errorlevel! neq 0 (
                if exist "!temp_audio_file!" ( del /f /q "!temp_audio_file!" )
                echo 设置失败
            ) else (
                powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('!audio_file!', 'OnlyErrorDialogs', 'SendToRecycleBin')"
                move /y "!temp_audio_file!" "!audio_file!" >nul
                echo 设置成功
            )
        ) else (
            echo 未找到封面图片，跳过
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
