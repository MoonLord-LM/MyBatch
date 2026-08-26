@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '查看视频文件的编码参数' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和统计当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只查看该文件；拖拽文件夹时，则递归查看其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
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

        set "video_codec="
        set "audio_codec="
        for /f "delims=" %%c in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of csv=p=0 $env:param1 2>$null"') do (
            set "video_codec=%%c"
        )
        for /f "delims=" %%c in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name,profile -of csv=p=0 $env:param1 2>$null"') do (
            set "audio_codec=%%c"
        )
        if "!video_codec!" == "" (
            echo 视频编码解析失败
        ) else (
            echo 视频编码：!video_codec!
        )
        if "!audio_codec!" == "" (
            echo 音频编码解析失败
        ) else (
            echo 音频编码：!audio_codec!
        )
    )
)

if not "!working_dir!" == "" (
    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"
    set "temp_video_codecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.video_codecs" & type nul > "!temp_video_codecs!"
    set "temp_audio_codecs=%temp%\MyBatch_%random%_%random%_%random%_%random%.audio_codecs" & type nul > "!temp_audio_codecs!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "parse_failed=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!"
        powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of csv=p=0 $env:video_file 2>$null" >>"!temp_video_codecs!"
        if !errorlevel! neq 0 (
            echo set /a "parse_failed+=1">>"!temp_set!"
            echo 视频编码解析失败
        ) else (
            powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_name,profile -of csv=p=0 $env:video_file 2>$null" >>"!temp_audio_codecs!"
            if !errorlevel! neq 0 (
                echo set /a "parse_failed+=1">>"!temp_set!"
                echo 音频编码解析失败
            ) else (
                echo set /a "succeeded+=1">>"!temp_set!"
            )
        )
        echo set /a "total+=1">>"!temp_set!"
        echo.

        endlocal
        endlocal
    )

    REM 执行 "!temp_set!" 中的变量赋值语句，完成变量的跨域传递
    call "!temp_set!" & if exist "!temp_set!" ( del /f /q "!temp_set!" )

    echo.
    echo ----------------------------------------
    echo.

    set /a "video_codec_count=0"
    echo 已发现的视频编码列表：
    (for /f "delims=" %%c in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-Content -Encoding UTF8 -LiteralPath $env:temp_video_codecs | Where-Object { $_ } | Sort-Object -Unique"') do (
        set "video_codec=%%c"
        if "!video_codec:~-1!"=="," set "video_codec=!video_codec:~0,-1!"
        echo !video_codec!
        set /a "video_codec_count+=1"
    )) & echo.

    set /a "audio_codec_count=0"
    echo 已发现的音频编码列表：
    (for /f "delims=" %%c in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-Content -Encoding UTF8 -LiteralPath $env:temp_audio_codecs | Where-Object { $_ } | Sort-Object -Unique"') do (
        set "audio_codec=%%c"
        if "!audio_codec:~-1!"=="," set "audio_codec=!audio_codec:~0,-1!"
        echo !audio_codec!
        set /a "audio_codec_count+=1"
    )) & echo.

    echo ----------------------------------------
    echo.
    echo 统计完成
    set /a "ok_total=succeeded"
    set /a "fail_total=parse_failed"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个，发现 !video_codec_count! 种视频编码、!audio_codec_count! 种音频编码。 & REM
    echo 其中，解析成功 !succeeded! 个，解析失败 !parse_failed! 个

    if exist "!temp_video_codecs!" ( del /f /q "!temp_video_codecs!" )
    if exist "!temp_audio_codecs!" ( del /f /q "!temp_audio_codecs!" )
)



echo.
pause
endlocal & endlocal & exit /b
