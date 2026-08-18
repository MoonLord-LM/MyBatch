@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将图片的修改时间，刷新为与文件名中的时间一致，默认使用系统时区' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持 IMG_YYYYMMDD_HHMMSS_fff、mmexport_YYYYMMDD_HHMMSS、QQ截图YYYYMMDDHHMMSS、Screenshot_YYYYMMDD_HHMMSS 的命名格式' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的图片文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个图片文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '不支持的命名格式的图片，不做处理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)



if "%~1" == "" (
    echo 开始处理当前文件夹: "!cd!"
    echo.

    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "already_ok=0"
    set /a "no_time=0"
    set /a "set_failed=0"
    set /a "not_standard=0"
    set "file_path=!cd!"
    set "ext_filter=\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "img_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!img_file!"

        REM 从标准命名中识别时间（Screenshot_/IMG_/mmexport_/QQ截图），识别不到则区分非标准命名与时间无效
        set "formatted_time="
        for /f "delims=" %%t in ('powershell -NoProfile -Command "$n=[IO.Path]::GetFileNameWithoutExtension($env:base_name); $t=''; $m=[regex]::Match($n,'^Screenshot_(\d{8})_(\d{6})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value } else { $m=[regex]::Match($n,'^IMG_(\d{8})_(\d{6})_(\d{3})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value+'_'+$m.Groups[3].Value } else { $m=[regex]::Match($n,'^mmexport_(\d{8})_(\d{6})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value } else { $m=[regex]::Match($n,'^QQ截图(\d{14})$'); if($m.Success){ $t=$m.Groups[1].Value.Substring(0,8)+'_'+$m.Groups[1].Value.Substring(8,6) } } } }; if($t -eq ''){ Write-Output 'NOSTD' } else { try { $fmt='yyyyMMdd_HHmmss'; if($t.Length -gt 15){ $fmt='yyyyMMdd_HHmmss_fff' }; $null=[datetime]::ParseExact($t,$fmt,[Globalization.CultureInfo]::InvariantCulture); Write-Output $t } catch { Write-Output 'NO_TIME' } }" 2^>nul') do (
            set "formatted_time=%%t"
        )

        if "!formatted_time!"=="NOSTD" (
            echo set /a "not_standard+=1">> "!temp_set!"
            echo 文件名不是标准命名，跳过此文件
        ) else if "!formatted_time!"=="NO_TIME" (
            echo set /a "no_time+=1">> "!temp_set!"
            echo 文件名中的时间无效，跳过此文件
        ) else (
            echo 图片文件名中的时间: "!formatted_time!"
            set "refresh_result="
            for /f "delims=" %%r in ('powershell -NoProfile -Command "$f=$env:img_file; $t=$env:formatted_time; try { $fmt='yyyyMMdd_HHmmss'; if($t.Length -gt 15){ $fmt='yyyyMMdd_HHmmss_fff' }; $dt=[datetime]::ParseExact($t,$fmt,[Globalization.CultureInfo]::InvariantCulture); $cur=(Get-Item -LiteralPath $f).LastWriteTime; if($cur.ToString($fmt) -eq $t){ Write-Output 'ALREADY' } else { (Get-Item -LiteralPath $f).LastWriteTime=$dt; Write-Output 'SET' } } catch { Write-Output 'FAIL' }" 2^>nul') do (
                set "refresh_result=%%r"
            )

            if "!refresh_result!"=="ALREADY" (
                echo set /a "already_ok+=1">> "!temp_set!"
                echo 修改时间已与文件名一致，无需处理
            ) else if "!refresh_result!"=="SET" (
                echo set /a "succeeded+=1">> "!temp_set!"
                echo 修改时间已刷新
            ) else (
                echo set /a "set_failed+=1">> "!temp_set!"
                echo 修改时间刷新失败
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
    set /a "fail_total=not_standard+no_time+set_failed"
    echo 共计: !total! 个，成功: !ok_total! 个，失败: !fail_total! 个& REM
    echo 其中，修改时间刷新成功 !succeeded! 个，已保持一致 !already_ok! 个，未识别到时间 !no_time! 个，刷新失败 !set_failed! 个，非标准命名跳过 !not_standard! 个
) else (
    setlocal disabledelayedexpansion
    set "img_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
    set "file_ext=%~x1"
    setlocal enabledelayedexpansion

    if not exist "!img_file!" (
        echo 错误: 文件不存在: "!img_file!"
        echo.
        pause
        exit /b 1
    )

    if exist "!img_file!\" (
        echo 开始处理文件夹: "!img_file!"
        echo.

        REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
        set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

        set /a "total=0"
        set /a "succeeded=0"
        set /a "already_ok=0"
        set /a "no_time=0"
        set /a "set_failed=0"
        set /a "not_standard=0"
        set "file_path=!img_file!"
        set "ext_filter=\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "img_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!img_file!"

            REM 从标准命名中识别时间（Screenshot_/IMG_/mmexport_/QQ截图），识别不到则区分非标准命名与时间无效
            set "formatted_time="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "$n=[IO.Path]::GetFileNameWithoutExtension($env:base_name); $t=''; $m=[regex]::Match($n,'^Screenshot_(\d{8})_(\d{6})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value } else { $m=[regex]::Match($n,'^IMG_(\d{8})_(\d{6})_(\d{3})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value+'_'+$m.Groups[3].Value } else { $m=[regex]::Match($n,'^mmexport_(\d{8})_(\d{6})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value } else { $m=[regex]::Match($n,'^QQ截图(\d{14})$'); if($m.Success){ $t=$m.Groups[1].Value.Substring(0,8)+'_'+$m.Groups[1].Value.Substring(8,6) } } } }; if($t -eq ''){ Write-Output 'NOSTD' } else { try { $fmt='yyyyMMdd_HHmmss'; if($t.Length -gt 15){ $fmt='yyyyMMdd_HHmmss_fff' }; $null=[datetime]::ParseExact($t,$fmt,[Globalization.CultureInfo]::InvariantCulture); Write-Output $t } catch { Write-Output 'NO_TIME' } }" 2^>nul') do (
                set "formatted_time=%%t"
            )

            if "!formatted_time!"=="NOSTD" (
                echo set /a "not_standard+=1">> "!temp_set!"
                echo 文件名不是标准命名，跳过此文件
            ) else if "!formatted_time!"=="NO_TIME" (
                echo set /a "no_time+=1">> "!temp_set!"
                echo 文件名中的时间无效，跳过此文件
            ) else (
                echo 图片文件名中的时间: "!formatted_time!"
                set "refresh_result="
                for /f "delims=" %%r in ('powershell -NoProfile -Command "$f=$env:img_file; $t=$env:formatted_time; try { $fmt='yyyyMMdd_HHmmss'; if($t.Length -gt 15){ $fmt='yyyyMMdd_HHmmss_fff' }; $dt=[datetime]::ParseExact($t,$fmt,[Globalization.CultureInfo]::InvariantCulture); $cur=(Get-Item -LiteralPath $f).LastWriteTime; if($cur.ToString($fmt) -eq $t){ Write-Output 'ALREADY' } else { (Get-Item -LiteralPath $f).LastWriteTime=$dt; Write-Output 'SET' } } catch { Write-Output 'FAIL' }" 2^>nul') do (
                    set "refresh_result=%%r"
                )

                if "!refresh_result!"=="ALREADY" (
                    echo set /a "already_ok+=1">> "!temp_set!"
                    echo 修改时间已与文件名一致，无需处理
                ) else if "!refresh_result!"=="SET" (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 修改时间已刷新
                ) else (
                    echo set /a "set_failed+=1">> "!temp_set!"
                    echo 修改时间刷新失败
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
        set /a "fail_total=not_standard+no_time+set_failed"
        echo 共计: !total! 个，成功: !ok_total! 个，失败: !fail_total! 个& REM
        echo 其中，修改时间刷新成功 !succeeded! 个，已保持一致 !already_ok! 个，未识别到时间 !no_time! 个，刷新失败 !set_failed! 个，非标准命名跳过 !not_standard! 个
    ) else (
        echo 开始处理文件: "!img_file!"

        REM 从标准命名中识别时间（Screenshot_/IMG_/mmexport_/QQ截图），识别不到则区分非标准命名与时间无效
        set "formatted_time="
        for /f "delims=" %%t in ('powershell -NoProfile -Command "$n=[IO.Path]::GetFileNameWithoutExtension($env:base_name); $t=''; $m=[regex]::Match($n,'^Screenshot_(\d{8})_(\d{6})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value } else { $m=[regex]::Match($n,'^IMG_(\d{8})_(\d{6})_(\d{3})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value+'_'+$m.Groups[3].Value } else { $m=[regex]::Match($n,'^mmexport_(\d{8})_(\d{6})$'); if($m.Success){ $t=$m.Groups[1].Value+'_'+$m.Groups[2].Value } else { $m=[regex]::Match($n,'^QQ截图(\d{14})$'); if($m.Success){ $t=$m.Groups[1].Value.Substring(0,8)+'_'+$m.Groups[1].Value.Substring(8,6) } } } }; if($t -eq ''){ Write-Output 'NOSTD' } else { try { $fmt='yyyyMMdd_HHmmss'; if($t.Length -gt 15){ $fmt='yyyyMMdd_HHmmss_fff' }; $null=[datetime]::ParseExact($t,$fmt,[Globalization.CultureInfo]::InvariantCulture); Write-Output $t } catch { Write-Output 'NO_TIME' } }" 2^>nul') do (
            set "formatted_time=%%t"
        )

        if "!formatted_time!"=="NOSTD" (
            echo 文件名不是标准命名，跳过此文件
        ) else if "!formatted_time!"=="NO_TIME" (
            echo 文件名中的时间无效，跳过此文件
        ) else (
            echo 图片文件名中的时间: "!formatted_time!"
            set "refresh_result="
            for /f "delims=" %%r in ('powershell -NoProfile -Command "$f=$env:img_file; $t=$env:formatted_time; try { $fmt='yyyyMMdd_HHmmss'; if($t.Length -gt 15){ $fmt='yyyyMMdd_HHmmss_fff' }; $dt=[datetime]::ParseExact($t,$fmt,[Globalization.CultureInfo]::InvariantCulture); $cur=(Get-Item -LiteralPath $f).LastWriteTime; if($cur.ToString($fmt) -eq $t){ Write-Output 'ALREADY' } else { (Get-Item -LiteralPath $f).LastWriteTime=$dt; Write-Output 'SET' } } catch { Write-Output 'FAIL' }" 2^>nul') do (
                set "refresh_result=%%r"
            )

            if "!refresh_result!"=="ALREADY" (
                echo 修改时间已与文件名一致，无需处理
            ) else if "!refresh_result!"=="SET" (
                echo 修改时间已刷新
            ) else (
                echo 修改时间刷新失败
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
