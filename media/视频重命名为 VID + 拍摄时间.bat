@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将视频按录制或编码的时间，重命名为 VID_YYYYMMDD_HHMMSS 格式，默认使用系统时区' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
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
    set /a "no_time=0"
    set /a "already_ok=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"
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
        set "creation_time="
        for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
            set "creation_time=%%x"
            echo 视频容器 creation_time 标记："!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -select_streams v -show_entries stream_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 视频流 creation_time 标记："!creation_time!"
            )
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format_tags^=com.apple.quicktime.creationdate -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 苹果 QuickTime 格式标记："!creation_time!"
            )
        )

        set "duration="
        for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
            set "duration=%%x"
            echo 视频时长："!duration!"
        )

        if "!creation_time!"=="" (
            echo set /a "no_time+=1">> "!temp_set!"
            echo 未找到创建时间，跳过此文件
        ) else (
            set "formatted_time="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($utcTime, $duration) try { $dt = [DateTime]::Parse($utcTime, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal); $start = $dt.AddSeconds(-[double]::Parse($duration, [Globalization.CultureInfo]::InvariantCulture)).ToLocalTime(); $start = $start.Date.AddSeconds([Math]::Floor($start.TimeOfDay.TotalSeconds)); Write-Output $start.ToString('yyyyMMdd_HHmmss') } catch { Write-Output 'ERROR' }} -utcTime '!creation_time!' -duration '!duration!'" 2^>nul') do (
                set "formatted_time=%%t"
            )

            if "!formatted_time!"=="" (
                echo set /a "no_time+=1">> "!temp_set!"
                echo 时间解析失败，跳过此文件
            ) else if "!formatted_time!"=="ERROR" (
                echo set /a "no_time+=1">> "!temp_set!"
                echo 时间解析失败，跳过此文件
            ) else (
                set "new_name=VID_!formatted_time!!file_ext!"
                echo 目标文件名："!new_name!"
                if /i "!video_file!"=="!file_dir!!new_name!" (
                    echo set /a "already_ok+=1">> "!temp_set!"
                    echo 文件名已符合规范，无需处理
                ) else if exist "!file_dir!!new_name!" (
                    echo set /a "name_conflict+=1">> "!temp_set!"
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!video_file!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 重命名成功
                    ) else (
                        echo set /a "rename_failed+=1">> "!temp_set!"
                        echo 重命名失败
                    )
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
    set /a "ok_total=succeeded+already_ok"
    set /a "fail_total=no_time+name_conflict+rename_failed"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，重命名成功 !succeeded! 个，已符合规范 !already_ok! 个，已存在同名文件 !name_conflict! 个，时间获取失败 !no_time! 个，重命名失败 !rename_failed! 个
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
        set /a "no_time=0"
        set /a "already_ok=0"
        set /a "name_conflict=0"
        set /a "rename_failed=0"
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
            set "creation_time="
            for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 视频容器 creation_time 标记："!creation_time!"
            )
            if "!creation_time!"=="" (
                for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -select_streams v -show_entries stream_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                    set "creation_time=%%x"
                    echo 视频流 creation_time 标记："!creation_time!"
                )
            )
            if "!creation_time!"=="" (
                for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format_tags^=com.apple.quicktime.creationdate -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                    set "creation_time=%%x"
                    echo 苹果 QuickTime 格式标记："!creation_time!"
                )
            )

            set "duration="
            for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "duration=%%x"
                echo 视频时长："!duration!"
            )

            if "!creation_time!"=="" (
                echo set /a "no_time+=1">> "!temp_set!"
                echo 未找到创建时间，跳过此文件
            ) else (
                set "formatted_time="
                for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($utcTime, $duration) try { $dt = [DateTime]::Parse($utcTime, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal); $start = $dt.AddSeconds(-[double]::Parse($duration, [Globalization.CultureInfo]::InvariantCulture)).ToLocalTime(); $start = $start.Date.AddSeconds([Math]::Floor($start.TimeOfDay.TotalSeconds)); Write-Output $start.ToString('yyyyMMdd_HHmmss') } catch { Write-Output 'ERROR' }} -utcTime '!creation_time!' -duration '!duration!'" 2^>nul') do (
                    set "formatted_time=%%t"
                )

                if "!formatted_time!"=="" (
                    echo set /a "no_time+=1">> "!temp_set!"
                    echo 时间解析失败，跳过此文件
                ) else if "!formatted_time!"=="ERROR" (
                    echo set /a "no_time+=1">> "!temp_set!"
                    echo 时间解析失败，跳过此文件
                ) else (
                    set "new_name=VID_!formatted_time!!file_ext!"
                    echo 目标文件名："!new_name!"
                    if /i "!video_file!"=="!file_dir!!new_name!" (
                        echo set /a "already_ok+=1">> "!temp_set!"
                        echo 文件名已符合规范，无需处理
                    ) else if exist "!file_dir!!new_name!" (
                        echo set /a "name_conflict+=1">> "!temp_set!"
                        echo 目标文件已存在，跳过此文件
                    ) else (
                        ren "!video_file!" "!new_name!"
                        if !errorlevel! equ 0 (
                            echo set /a "succeeded+=1">> "!temp_set!"
                            echo 重命名成功
                        ) else (
                            echo set /a "rename_failed+=1">> "!temp_set!"
                            echo 重命名失败
                        )
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
        set /a "ok_total=succeeded+already_ok"
        set /a "fail_total=no_time+name_conflict+rename_failed"
        echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
        echo 其中，重命名成功 !succeeded! 个，已符合规范 !already_ok! 个，已存在同名文件 !name_conflict! 个，时间获取失败 !no_time! 个，重命名失败 !rename_failed! 个
    ) else (
        set "ext_ok="
        for /f "delims=" %%e in ('powershell -NoProfile -Command "if ($env:file_ext -match '^\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$'){Write-Output 'ok'}" 2^>nul') do set "ext_ok=%%e"
        if not "!ext_ok!"=="ok" (
            echo 错误：不支持的视频格式："!video_file!"
            echo.
            pause
            exit /b 1
        )
        echo 开始处理文件："!video_file!"
        set "creation_time="
        for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
            set "creation_time=%%x"
            echo 视频容器 creation_time 标记："!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -select_streams v -show_entries stream_tags^=creation_time -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 视频流 creation_time 标记："!creation_time!"
            )
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format_tags^=com.apple.quicktime.creationdate -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 苹果 QuickTime 格式标记："!creation_time!"
            )
        )

        set "duration="
        for /f "delims=" %%x in ('call "!ffprobe_path!" -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "!video_file!" 2^>nul') do (
            set "duration=%%x"
            echo 视频时长："!duration!"
        )

        if "!creation_time!"=="" (
            echo 未找到创建时间，跳过此文件
        ) else (
            set "formatted_time="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($utcTime, $duration) try { $dt = [DateTime]::Parse($utcTime, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal); $start = $dt.AddSeconds(-[double]::Parse($duration, [Globalization.CultureInfo]::InvariantCulture)).ToLocalTime(); $start = $start.Date.AddSeconds([Math]::Floor($start.TimeOfDay.TotalSeconds)); Write-Output $start.ToString('yyyyMMdd_HHmmss') } catch { Write-Output 'ERROR' }} -utcTime '!creation_time!' -duration '!duration!'" 2^>nul') do (
                set "formatted_time=%%t"
            )

            if "!formatted_time!"=="" (
                echo 时间解析失败，跳过此文件
            ) else if "!formatted_time!"=="ERROR" (
                echo 时间解析失败，跳过此文件
            ) else (
                set "new_name=VID_!formatted_time!!file_ext!"
                echo 目标文件名："!new_name!"
                if /i "!video_file!"=="!file_dir!!new_name!" (
                    echo 文件名已符合规范，无需处理
                ) else if exist "!file_dir!!new_name!" (
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!video_file!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo 重命名成功
                    ) else (
                        echo 重命名失败
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
