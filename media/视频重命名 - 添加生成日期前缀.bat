@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '给视频文件添加生成日期前缀，默认使用系统时区' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的视频文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个视频文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 mp4 mkv ts avi wmv flv rmvb rm vob mpg mpeg 3gp m4v f4v mov webm' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '特殊场景：没有内置的时间信息标记时，如果文件名符合微信导出的 mmexport + 13 位时间戳 的格式，从文件名识别导出时间' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '特殊场景：没有内置的时间信息标记时，尝试识别文件名末尾的 [av数字] 标记，联网查询 B 站最相邻 av 号的视频的发布时间' -ForegroundColor Green"
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
        set "file_dir=!param1_dir!"
        set "base_name=!param1_name!"
        set "file_ext=!param1_ext!"

        set "creation_date="
        set "video_file=!param1!"
        for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
            set "creation_date=%%a"
        )
        if not "!creation_date!"=="" echo 视频容器 date 标记："!creation_date!"
        if "!creation_date!"=="" (
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 视频容器 creation_time 标记："!creation_date!"
        )
        if "!creation_date!"=="" (
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams v -show_entries stream_tags=creation_time -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 视频流 creation_time 标记："!creation_date!"
        )
        if "!creation_date!"=="" (
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -show_entries format_tags=com.apple.quicktime.creationdate -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 苹果 QuickTime 格式标记："!creation_date!"
        )
        if "!creation_date!"=="" (
            REM 识别微信导出视频文件名中的保存时间（mmexport + 13 位毫秒时间戳，UTC），转换为系统时区日期
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; $n=$env:base_name; $m=[regex]::Match($n,'mmexport(\d{13})'); if($m.Success){ try { $dt=[DateTimeOffset]::FromUnixTimeMilliseconds([int64]$m.Groups[1].Value).ToLocalTime(); Write-Output $dt.ToString('yyyyMMdd') } catch {} }" 2^>nul') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 微信文件名的导出时间："!creation_date!"
        )
        if "!creation_date!"=="" (
            REM 联网查询 B 站最相邻 av 号的视频的发布时间，网络超时时间 30 秒，av 号最多尝试 10 个
            set "bili_out_file=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!bili_out_file!"
            powershell -NoProfile -Command ^
                "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
                "$bn=$env:base_name;" ^
                "$m=[regex]::Match($bn,'\[av(\d+)\]$');" ^
                "if(-not $m.Success) { exit; }" ^
                "$av=[int64]$m.Groups[1].Value;" ^
                "$out='';" ^
                "for($k=0;$k -lt 10;$k++) {" ^
                "    $cur=$av-$k;" ^
                "    $url='https://www.bilibili.com/video/av'+$cur+'/';" ^
                "    $ProgressPreference='SilentlyContinue';" ^
                "    try {" ^
                "        $html=(Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content;" ^
                "        $mm=[regex]::Match($html,'__INITIAL_STATE__\s*=\s*(\{.*?\});\(function','Singleline');" ^
                "        if($mm.Success) {" ^
                "            $json=$mm.Groups[1].Value|ConvertFrom-Json;" ^
                "            $vd=$json.videoData;" ^
                "            if($vd -and $vd.pubdate -gt 0) {" ^
                "                $dt=([datetime]'1970-01-01').AddSeconds($vd.pubdate).ToLocalTime();" ^
                "                Write-Host ('[av'+$cur+'] '+$vd.title+' / '+$vd.owner.name+' / '+$dt.ToString('yyyy-MM-dd HH:mm:ss'));" ^
                "                Write-Host ('[av'+$cur+'] URL: '+$url);" ^
                "                $out=$dt.ToString('yyyyMMdd');" ^
                "                break;" ^
                "            } else {" ^
                "                Write-Host ('[av'+$cur+'] no valid data');" ^
                "            }" ^
                "        } else {" ^
                "            Write-Host ('[av'+$cur+'] data not found');" ^
                "        }" ^
                "    } catch {" ^
                "        Write-Host ('[av'+$cur+'] error: '+$_.Exception.Message);" ^
                "    }" ^
                "}" ^
                "if($out) { Set-Content -LiteralPath $env:bili_out_file -Value $out -Encoding UTF8 -NoNewline; }"
            if exist "!bili_out_file!" ( set /p "creation_date="<"!bili_out_file!" )
            if exist "!bili_out_file!" ( del /f /q "!bili_out_file!" )
            if not "!creation_date!"=="" (
                echo 尝试获取 B 站 av 号的发布时间："!creation_date!"
            )
        )

        if "!creation_date!"=="" (
            echo 未找到生成日期，跳过此文件
        ) else (
            set "formatted_date="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & { param($timeStr) try { Write-Output $(if ($timeStr.Length -eq 8) { [DateTime]::ParseExact($timeStr, 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture).ToLocalTime().ToString('yyyyMMdd') } else { [DateTime]::Parse($timeStr, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal).ToLocalTime().ToString('yyyyMMdd') }) } catch { } } -timeStr '!creation_date!'" 2^>nul') do (
                set "formatted_date=%%t"
            )
            if "!formatted_date!"=="" (
                echo 时间解析失败，跳过此文件
            ) else (
                set "prefix=!formatted_date! "
                echo 日期前缀："!prefix!"
                if "!base_name:~0,9!"=="!prefix!" (
                    echo 文件名已包含日期前缀，跳过此文件
                ) else (
                    set "new_name=!prefix!!base_name!!file_ext!"
                    echo 目标文件名："!new_name!"
                    if exist "!file_dir!!new_name!" (
                        echo 目标文件已存在，跳过此文件
                    ) else (
                        ren "!param1!" "!new_name!"
                        if !errorlevel! equ 0 (
                            echo 重命名成功
                        ) else (
                            echo 重命名失败
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
    set /a "no_date=0"
    set /a "already_ok=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(mp4|mkv|ts|avi|wmv|flv|rmvb|rm|vob|mpg|mpeg|3gp|m4v|f4v|mov|webm)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "video_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 处理文件："!video_file!"
        set "creation_date="
        for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
            set "creation_date=%%a"
        )
        if not "!creation_date!"=="" echo 视频容器 date 标记："!creation_date!"
        if "!creation_date!"=="" (
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 视频容器 creation_time 标记："!creation_date!"
        )
        if "!creation_date!"=="" (
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -select_streams v -show_entries stream_tags=creation_time -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 视频流 creation_time 标记："!creation_date!"
        )
        if "!creation_date!"=="" (
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & $env:ffprobe_path -v error -show_entries format_tags=com.apple.quicktime.creationdate -of default=noprint_wrappers=1:nokey=1 $env:video_file 2>$null"') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 苹果 QuickTime 格式标记："!creation_date!"
        )
        if "!creation_date!"=="" (
            REM 识别微信导出视频文件名中的保存时间（mmexport + 13 位毫秒时间戳，UTC），转换为系统时区日期
            for /f "delims=" %%a in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; $n=$env:base_name; $m=[regex]::Match($n,'mmexport(\d{13})'); if($m.Success){ try { $dt=[DateTimeOffset]::FromUnixTimeMilliseconds([int64]$m.Groups[1].Value).ToLocalTime(); Write-Output $dt.ToString('yyyyMMdd') } catch {} }" 2^>nul') do (
                set "creation_date=%%a"
            )
            if not "!creation_date!"=="" echo 微信文件名的导出时间："!creation_date!"
        )
        if "!creation_date!"=="" (
            REM 联网查询 B 站最相邻 av 号的视频的发布时间，网络超时时间 30 秒，av 号最多尝试 10 个
            set "bili_out_file=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!bili_out_file!"
            powershell -NoProfile -Command ^
                "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
                "$bn=$env:base_name;" ^
                "$m=[regex]::Match($bn,'\[av(\d+)\]$');" ^
                "if(-not $m.Success) { exit; }" ^
                "$av=[int64]$m.Groups[1].Value;" ^
                "$out='';" ^
                "for($k=0;$k -lt 10;$k++) {" ^
                "    $cur=$av-$k;" ^
                "    $url='https://www.bilibili.com/video/av'+$cur+'/';" ^
                "    $ProgressPreference='SilentlyContinue';" ^
                "    try {" ^
                "        $html=(Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content;" ^
                "        $mm=[regex]::Match($html,'__INITIAL_STATE__\s*=\s*(\{.*?\});\(function','Singleline');" ^
                "        if($mm.Success) {" ^
                "            $json=$mm.Groups[1].Value|ConvertFrom-Json;" ^
                "            $vd=$json.videoData;" ^
                "            if($vd -and $vd.pubdate -gt 0) {" ^
                "                $dt=([datetime]'1970-01-01').AddSeconds($vd.pubdate).ToLocalTime();" ^
                "                Write-Host ('[av'+$cur+'] '+$vd.title+' / '+$vd.owner.name+' / '+$dt.ToString('yyyy-MM-dd HH:mm:ss'));" ^
                "                Write-Host ('[av'+$cur+'] URL: '+$url);" ^
                "                $out=$dt.ToString('yyyyMMdd');" ^
                "                break;" ^
                "            } else {" ^
                "                Write-Host ('[av'+$cur+'] no valid data');" ^
                "            }" ^
                "        } else {" ^
                "            Write-Host ('[av'+$cur+'] data not found');" ^
                "        }" ^
                "    } catch {" ^
                "        Write-Host ('[av'+$cur+'] error: '+$_.Exception.Message);" ^
                "    }" ^
                "}" ^
                "if($out) { Set-Content -LiteralPath $env:bili_out_file -Value $out -Encoding UTF8 -NoNewline; }"
            if exist "!bili_out_file!" ( set /p "creation_date="<"!bili_out_file!" )
            if exist "!bili_out_file!" ( del /f /q "!bili_out_file!" )
            if not "!creation_date!"=="" (
                echo 尝试获取 B 站 av 号的发布时间："!creation_date!"
            )
        )

        if "!creation_date!"=="" (
            echo set /a "no_date+=1">>"!temp_set!"
            echo 未找到生成日期，跳过此文件
        ) else (
            set "formatted_date="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & { param($timeStr) try { Write-Output $(if ($timeStr.Length -eq 8) { [DateTime]::ParseExact($timeStr, 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture).ToLocalTime().ToString('yyyyMMdd') } else { [DateTime]::Parse($timeStr, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal).ToLocalTime().ToString('yyyyMMdd') }) } catch { } } -timeStr '!creation_date!'" 2^>nul') do (
                set "formatted_date=%%t"
            )
            if "!formatted_date!"=="" (
                echo set /a "no_date+=1">>"!temp_set!"
                echo 时间解析失败，跳过此文件
            ) else (
                set "prefix=!formatted_date! "
                echo 日期前缀："!prefix!"
                if "!base_name:~0,9!"=="!prefix!" (
                    echo set /a "already_ok+=1">>"!temp_set!"
                    echo 文件名已包含日期前缀，跳过此文件
                ) else (
                    set "new_name=!prefix!!base_name!!file_ext!"
                    echo 目标文件名："!new_name!"
                    if exist "!file_dir!!new_name!" (
                        echo set /a "name_conflict+=1">>"!temp_set!"
                        echo 目标文件已存在，跳过此文件
                    ) else (
                        ren "!video_file!" "!new_name!"
                        if !errorlevel! equ 0 (
                            echo set /a "succeeded+=1">>"!temp_set!"
                            echo 重命名成功
                        ) else (
                            echo set /a "rename_failed+=1">>"!temp_set!"
                            echo 重命名失败
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
    set /a "ok_total=succeeded+already_ok"
    set /a "fail_total=no_date+name_conflict+rename_failed"
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，重命名成功 !succeeded! 个，已包含日期前缀 !already_ok! 个，已存在同名文件 !name_conflict! 个，日期获取失败 !no_date! 个，重命名失败 !rename_failed! 个
)



echo.
pause
endlocal & endlocal & exit /b
