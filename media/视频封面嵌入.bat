@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将同名的图片文件、cover.png 或 cover.jpg，设置为视频的封面' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

set "ffmpeg_path=ffmpeg"
if exist "%~dp0ffmpeg.exe" (
    set "ffmpeg_path=%~dp0ffmpeg.exe"
) else if exist "!cd!\ffmpeg.exe" (
    set "ffmpeg_path=!cd!\ffmpeg.exe"
)
!ffmpeg_path! -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 ffmpeg 组件
    echo 请从 https://ffmpeg.org/download.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://ffmpeg.org/download.html"
    echo.
    pause
    exit /b 1
)
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
    set /a "has_cover=0"
    set /a "no_cover_file=0"
    set /a "set_failed=0"
    set "file_path=!cd!"
    set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理："!video_file!"
        set "has_cover=0"
        for /f "delims=" %%c in ('call "!ffprobe_path!" -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!video_file!" 2^>nul') do (
            if "%%c"=="1" (
                set "has_cover=1"
            )
        )

        if "!has_cover!"=="1" (
            echo set /a "has_cover+=1">> "!temp_set!"
            echo 已有封面，跳过
        ) else (
            set "cover_file="
            if exist "!file_dir!!base_name!.png" (
                set "cover_file=!file_dir!!base_name!.png"
            ) else if exist "!file_dir!!base_name!.jpg" (
                set "cover_file=!file_dir!!base_name!.jpg"
            ) else if exist "!file_dir!cover.png" (
                set "cover_file=!file_dir!cover.png"
            ) else if exist "!file_dir!cover.jpg" (
                set "cover_file=!file_dir!cover.jpg"
            )

            if not "!cover_file!"=="" (
                echo 找到封面："!cover_file!"
                set "temp_video_file=!file_dir!!base_name!_temp!file_ext!"
                "!ffmpeg_path!" -i "!video_file!" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "!temp_video_file!"
                if !errorlevel! neq 0 (
                    echo set /a "set_failed+=1">> "!temp_set!"
                    if exist "!temp_video_file!" ( del /f /q "!temp_video_file!" )
                    echo 设置失败
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:video_file,'OnlyErrorDialogs','SendToRecycleBin')"
                    move /y "!temp_video_file!" "!video_file!" >nul
                    echo 设置成功
                )
            ) else (
                echo set /a "no_cover_file+=1">> "!temp_set!"
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
    set /a "ok_total=succeeded"
    set /a "fail_total=has_cover+set_failed+no_cover_file"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，设置成功 !succeeded! 个，设置失败 !set_failed! 个，未找到封面图片 !no_cover_file! 个，已有封面 !has_cover! 个
) else (
    setlocal disabledelayedexpansion
    set "video_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    set "file_ext=%~x1"
    setlocal enabledelayedexpansion

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
        set /a "has_cover=0"
        set /a "no_cover_file=0"
        set /a "set_failed=0"
        set "file_path=!video_file!"
        set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "video_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 正在处理："!video_file!"
            set "has_cover=0"
            for /f "delims=" %%c in ('call "!ffprobe_path!" -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!video_file!" 2^>nul') do (
                if "%%c"=="1" (
                    set "has_cover=1"
                )
            )

            if "!has_cover!"=="1" (
                echo set /a "has_cover+=1">> "!temp_set!"
                echo 已有封面，跳过
            ) else (
                set "cover_file="
                if exist "!file_dir!!base_name!.png" (
                    set "cover_file=!file_dir!!base_name!.png"
                ) else if exist "!file_dir!!base_name!.jpg" (
                    set "cover_file=!file_dir!!base_name!.jpg"
                ) else if exist "!file_dir!cover.png" (
                    set "cover_file=!file_dir!cover.png"
                ) else if exist "!file_dir!cover.jpg" (
                    set "cover_file=!file_dir!cover.jpg"
                )

                if not "!cover_file!"=="" (
                    echo 找到封面："!cover_file!"
                    set "temp_video_file=!file_dir!!base_name!_temp!file_ext!"
                    "!ffmpeg_path!" -i "!video_file!" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "!temp_video_file!"
                    if !errorlevel! neq 0 (
                        echo set /a "set_failed+=1">> "!temp_set!"
                        if exist "!temp_video_file!" ( del /f /q "!temp_video_file!" )
                        echo 设置失败
                    ) else (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:video_file,'OnlyErrorDialogs','SendToRecycleBin')"
                        move /y "!temp_video_file!" "!video_file!" >nul
                        echo 设置成功
                    )
                ) else (
                    echo set /a "no_cover_file+=1">> "!temp_set!"
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
        set /a "ok_total=succeeded"
        set /a "fail_total=has_cover+set_failed+no_cover_file"
        echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
        echo 其中，设置成功 !succeeded! 个，设置失败 !set_failed! 个，未找到封面图片 !no_cover_file! 个，已有封面 !has_cover! 个
    ) else (
        echo 开始处理文件："!video_file!"

        set "has_cover=0"
        for /f "delims=" %%c in ('call "!ffprobe_path!" -v error -select_streams v -show_entries stream_disposition^=attached_pic -of csv^=p^=0 "!video_file!" 2^>nul') do (
            if "%%c"=="1" (
                set "has_cover=1"
            )
        )

        if "!has_cover!"=="1" (
            echo 已有封面，跳过
        ) else (
            set "cover_file="
            if exist "!file_dir!!base_name!.png" (
                set "cover_file=!file_dir!!base_name!.png"
            ) else if exist "!file_dir!!base_name!.jpg" (
                set "cover_file=!file_dir!!base_name!.jpg"
            ) else if exist "!file_dir!cover.png" (
                set "cover_file=!file_dir!cover.png"
            ) else if exist "!file_dir!cover.jpg" (
                set "cover_file=!file_dir!cover.jpg"
            )

            if not "!cover_file!"=="" (
                echo 找到封面："!cover_file!"
                set "temp_video_file=!file_dir!!base_name!_temp!file_ext!"
                "!ffmpeg_path!" -i "!video_file!" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "!temp_video_file!"
                if !errorlevel! neq 0 (
                    if exist "!temp_video_file!" ( del /f /q "!temp_video_file!" )
                    echo 设置失败
                ) else (
                    powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:video_file,'OnlyErrorDialogs','SendToRecycleBin')"
                    move /y "!temp_video_file!" "!video_file!" >nul
                    echo 设置成功
                )
            ) else (
                echo 未找到封面图片，跳过
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
