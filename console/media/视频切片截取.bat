@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
set "param2=%~2"
set "param3=%~3"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '根据输入的视频、开始时间、结束时间（可选），对视频做无损的切片截取' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入视频文件的路径；也可以拖拽单个视频文件到此脚本上' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '对一个文件处理完成后，可继续输入下一个文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '视频如果是 ts 格式，会自动转为同名的 mp4 后再截取，避免音画不同步问题' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '开始和结束时间的格式为 HH:MM:SS 或 HH:MM:SS.XXX，例如 00:01:23.456' -ForegroundColor Green"
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



set "video_file=!param1!"
set "begin_time=!param2!"
set "end_time=!param3!"

:loop

    :input_file
        if "!video_file!"=="" (
            echo 请输入要处理的视频文件：
            set /p "video_file="
            if !errorlevel! neq 0 (
                echo 无输入，退出脚本
                echo.
                exit /b 1
            )
            echo.
        ) else (
            echo 要处理的视频文件："!video_file!"
            echo.
        )
        if "!video_file!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_file
        )
        set "video_file=!video_file:"=!"
        if "!video_file!"=="" (
            echo 输入不能为空，请重新输入
            echo.
            goto input_file
        )
        if "!video_file:~-1!"=="\" set "video_file=!video_file:~0,-1!"
        if not exist "!video_file!" (
            echo 文件不存在 "!video_file!"，请重新输入
            echo.
            set "video_file="
            goto input_file
        )
        if exist "!video_file!\" (
            echo 不支持文件夹 "!video_file!"，请重新输入
            echo.
            set "video_file="
            goto input_file
        )

    :input_begin_time
        if "!begin_time!"=="" (
            echo 请输入开始时间，格式: HH:MM:SS.XXX：
            set /p "begin_time="
            if !errorlevel! neq 0 (
                echo 无输入，退出脚本
                echo.
                exit /b 1
            )
            echo.
        ) else (
            echo 开始时间："!begin_time!"
            echo.
        )
        if "!begin_time!"=="" (
            echo 开始时间不能为空
            echo.
            goto input_begin_time
        )

    :input_end_time
        if "!end_time!"=="" (
            echo 请输入结束时间，格式: HH:MM:SS.XXX，留空则截取到视频结尾：
            set /p "end_time="
            if !errorlevel! neq 0 (
                echo 无输入，继续脚本
            )
            echo.
        ) else (
            echo 结束时间："!end_time!"
            echo.
        )



    for %%i in ("!video_file!") do (
        setlocal disabledelayedexpansion
        set "file_dir=%%~dpi"
        set "base_name=%%~ni"
        set "file_ext=%%~xi"
        if /i "%%~xi"==".ts" ( set "new_file=%%~dpi%%~ni.mp4" )
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!" & REM
        if "!end_time!"=="" ( set "end_display=视频结尾" ) else ( set "end_display=!end_time!" )
        echo 截取时间：!begin_time! - !end_display!
        echo.

        if /i "!file_ext!"==".ts" (
            if exist "!new_file!" (
                echo 已存在同名 mp4 文件 "!new_file!"，优先使用该格式的文件处理
            ) else (
                echo 检测到 ts 格式，先转为同名 mp4："!new_file!"
                "!ffmpeg_path!" -y -i "!video_file!" -c copy "!new_file!" >nul 2>&1
                if !errorlevel! neq 0 (
                    echo.
                    echo ts 转 mp4 失败，程序退出
                    echo.
                    pause
                    exit /b 1
                )
                echo ts 转 mp4 完成
            )
            set "video_file=!new_file!"
        )

        REM 把开始/结束时间里的 : 和 . 替换为空，作为输出文件名
        set "begin=!begin_time::=!"
        set "begin=!begin:.=!"
        if "!end_time!"=="" (
            set "output_file=!file_dir!!base_name!_!begin!-end.mp4"
        ) else (
            set "end_name=!end_time::=!"
            set "end_name=!end_name:.=!"
            set "output_file=!file_dir!!base_name!_!begin!-!end_name!.mp4"
        )

        REM 关键帧分析（仅提示附近关键帧位置，仍按输入的开始/结束时间截取）
        if not "!ffprobe_path!"=="" (
            echo 正在分析附近的关键帧位置 ...
            powershell -NoProfile -Command ^
                "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
                "$ff=$env:ffprobe_path; $vid=$env:video_file; $b=$env:begin_time; $e=$env:end_time;" ^
                "function F($s){if([string]::IsNullOrWhiteSpace($s)){return $null}try{return [TimeSpan]::Parse($s.Trim()).TotalSeconds}catch{return $null}}" ^
                "$bs=F $b; $es=F $e;" ^
                "$raw=& $ff -v error -select_streams v:0 -skip_frame nokey -show_entries frame=pts_time -of csv=p=0 $vid 2>$null;" ^
                "$ks=@($raw|Where-Object{$_ -match '^[\d]'}|ForEach-Object{[double]$_});" ^
                "function T($x){$t=[TimeSpan]::FromSeconds($x);return ('{0:00}:{1:00}:{2:00}.{3:000}' -f [int]$t.TotalHours,$t.Minutes,$t.Seconds,[int]$t.Milliseconds)}" ^
                "function N($lab,$t){if($null -eq $t){return}; $bf=@($ks|Where-Object{$_ -le $t}|Sort-Object -Descending|Select-Object -First 3); $af=@($ks|Where-Object{$_ -gt $t}|Sort-Object|Select-Object -First 3); $cs=@(($bf+$af)|Sort-Object -Unique); Write-Host ('['+$lab+'] 输入时间 '+(T $t)) -ForegroundColor Yellow; if($cs.Count -eq 0){Write-Host '  附近未找到关键帧';return}; foreach($c in $cs){$m=if([Math]::Abs($c-$t) -lt 0.001){'  <-- 正好是关键帧'}else{''}; Write-Host ('  '+(T $c)+$m)}}" ^
                "N '开始时间附近关键帧' $bs;" ^
                "if($null -ne $es){N '结束时间附近关键帧' $es}"
            if !errorlevel! neq 0 (
                echo 关键帧分析失败，将继续按输入参数截取
            )
            echo.
        ) else (
            echo 未找到 ffprobe 组件，跳过关键帧分析，直接按输入参数截取
            echo.
        )

        set "end_args="
        if not "!end_time!"=="" set "end_args=-to "!end_time!""
        if exist "!output_file!" (
            echo 已存在："!output_file!"，跳过
        ) else (
            echo 正在截取："!output_file!"
            "!ffmpeg_path!" -y -ss "!begin_time!" !end_args! -i "!video_file!" -c copy -movflags +faststart "!output_file!"
            if !errorlevel! neq 0 (
                if exist "!output_file!" ( del /f /q "!output_file!" )
                echo 视频截取失败
            ) else (
                echo 视频截取成功
                echo 输出文件："!output_file!"
            )
        )

        endlocal
        endlocal
    )

    echo.
    set "video_file="
    set "begin_time="
    set "end_time="

goto loop



echo.
pause
exit /b
