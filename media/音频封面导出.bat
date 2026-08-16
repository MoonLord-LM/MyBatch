@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '导出音频封面为同名的 png 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的音频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个音频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 flac mp3' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

set "ffmpeg_path="
if exist "%~dp0ffmpeg.exe" (
    set "ffmpeg_path=%~dp0ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
)
if not defined ffmpeg_path (
    echo 错误: 缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)
set "ffprobe_path="
if exist "%~dp0ffprobe.exe" (
    set "ffprobe_path=%~dp0ffprobe.exe"
) else if exist "!cd!\ffprobe.exe" (
    set "ffprobe_path=!cd!\ffprobe.exe"
)
if not defined ffprobe_path (
    echo 错误: 缺少 ffprobe 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)



if "%~1" == "" (
    echo 开始处理当前文件夹: "!cd!"
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "skipped=0"
    set /a "failed=0"
    set "file_path=!cd!"
    set "ext_filter=\.(flac|mp3)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "audio_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!audio_file!"
        set "cover_file=!file_dir!!base_name!.png"
        if exist "!cover_file!" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 已存在: "!cover_file!"，跳过此文件
        ) else (
            set "has_cover=0"
            for /f "delims=" %%c in ('"!ffprobe_path!" -v error -select_streams v -show_entries stream^=codec_name -of csv^=p^=0 "!audio_file!" 2^>nul') do (
                set "has_cover=1"
            )

            if "!has_cover!"=="0" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 无封面
            ) else (
                "!ffmpeg_path!" -i "!audio_file!" -an -vcodec copy "!cover_file!"
                if !errorlevel! neq 0 (
                    echo set /a "failed+=1">> "!temp_set!"
                    if exist "!cover_file!" ( del /f /q "!cover_file!" )
                    echo 导出失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 保存文件: "!cover_file!"
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
    set "audio_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    setlocal enabledelayedexpansion

    if not exist "!audio_file!" (
        echo 错误: 文件不存在: "!audio_file!"
        echo.
        pause
        exit /b 1
    )

    if exist "!audio_file!\" (
        echo 开始处理文件夹: "!audio_file!"
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "skipped=0"
        set /a "failed=0"
        set "file_path=!audio_file!"
        set "ext_filter=\.(flac|mp3)$"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "audio_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!audio_file!"
            set "cover_file=!file_dir!!base_name!.png"
            if exist "!cover_file!" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 已存在: "!cover_file!"，跳过此文件
            ) else (
                set "has_cover=0"
                for /f "delims=" %%c in ('"!ffprobe_path!" -v error -select_streams v -show_entries stream^=codec_name -of csv^=p^=0 "!audio_file!" 2^>nul') do (
                    set "has_cover=1"
                )

                if "!has_cover!"=="0" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 无封面
                ) else (
                    "!ffmpeg_path!" -i "!audio_file!" -an -vcodec copy "!cover_file!"
                    if !errorlevel! neq 0 (
                        echo set /a "failed+=1">> "!temp_set!"
                        if exist "!cover_file!" ( del /f /q "!cover_file!" )
                        echo 导出失败
                    ) else (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 保存文件: "!cover_file!"
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
        echo 开始处理文件: "!audio_file!"
        set "cover_file=!file_dir!!base_name!.png"
        if exist "!cover_file!" (
            echo 已存在: "!cover_file!"，跳过此文件
        ) else (
            set "has_cover=0"
            for /f "delims=" %%c in ('"!ffprobe_path!" -v error -select_streams v -show_entries stream^=codec_name -of csv^=p^=0 "!audio_file!" 2^>nul') do (
                set "has_cover=1"
            )

            if "!has_cover!"=="0" (
                echo 无封面
            ) else (
                "!ffmpeg_path!" -i "!audio_file!" -an -vcodec copy "!cover_file!"
                if !errorlevel! neq 0 (
                    if exist "!cover_file!" ( del /f /q "!cover_file!" )
                    echo 导出失败
                ) else (
                    echo 保存文件: "!cover_file!"
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
