@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将图片按文件最后修改时间，重命名为 QQ截图YYYYMMDDHHMMSS 格式，默认使用系统时区' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的图片文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个图片文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg png bmp gif' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '带有 EXIF 拍摄时间的图片会被跳过，不做处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '以 Screenshot、IMG 开头的图片，不做处理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

REM 优先使用脚本所在文件夹中的 MediaInfo 组件（用于检测图片的 EXIF 拍摄时间）
set "mediainfo_path=mediainfo"
if exist "%~dp0MediaInfo.exe" (
    set "mediainfo_path=%~dp0MediaInfo.exe"
) else if exist "!cd!\MediaInfo.exe" (
    set "mediainfo_path=!cd!\MediaInfo.exe"
)
!mediainfo_path! --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误: 缺少 MediaInfo 组件
    echo 请从 https://mediaarea.net/en/MediaInfo 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://mediaarea.net/en/MediaInfo"
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
    set /a "no_time=0"
    set /a "already_ok=0"
    set /a "name_conflict=0"
    set /a "rename_failed=0"
    set /a "has_exif=0"
    set /a "other_prefix=0"
    set "file_path=!cd!"
    set "ext_filter=\.(jpg|png|bmp|gif)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "img_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!img_file!"

        REM 检查图片是否带有 EXIF 拍摄时间（Recorded_Date / Encoded_Date）
        set "creation_time="
        for /f "delims=" %%x in ('call "!mediainfo_path!" --Output^="General;%%Recorded_Date%%" "!img_file!" 2^>nul') do (
            set "creation_time=%%x"
            echo 图片 Recorded_Date 标记: "!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('call "!mediainfo_path!" --Output^="General;%%Encoded_Date%%" "!img_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 图片 Encoded_Date 标记: "!creation_time!"
            )
        )
        set "exif_time="
        if not "!creation_time!"=="" (
            for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($t) try { $s = $t -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3'; $dt = [DateTime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture); Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff') } catch {} } -t '!creation_time!'" 2^>nul') do (
                set "exif_time=%%t"
            )
        )

        if not "!exif_time!"=="" (
            echo set /a "has_exif+=1">> "!temp_set!"
            echo 图片带有拍摄时间，跳过此文件
        ) else if /i "!base_name:~0,10!"=="Screenshot" (
            echo set /a "other_prefix+=1">> "!temp_set!"
            echo 文件名以 Screenshot 开头，跳过此文件
        ) else if /i "!base_name:~0,3!"=="IMG" (
            echo set /a "other_prefix+=1">> "!temp_set!"
            echo 文件名以 IMG 开头，跳过此文件
        ) else (
            set "formatted_time="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "(Get-Item -LiteralPath $env:img_file).LastWriteTime.ToString('yyyyMMddHHmmss')" 2^>nul') do (
                set "formatted_time=%%t"
                echo 图片文件修改时间: "!formatted_time!"
            )

            if "!formatted_time!"=="" (
                echo set /a "no_time+=1">> "!temp_set!"
                echo 时间获取失败，跳过此文件
            ) else (
                for /f "delims=" %%l in ('powershell -NoProfile -Command "$env:file_ext.ToLower()"') do (
                    set "lower_file_ext=%%l"
                )
                set "new_name=QQ截图!formatted_time!!lower_file_ext!"
                echo 目标文件名: "!new_name!"
                if /i "!img_file!"=="!file_dir!!new_name!" (
                    echo set /a "already_ok+=1">> "!temp_set!"
                    echo 文件名已符合规范，无需处理
                ) else if exist "!file_dir!!new_name!" (
                    echo set /a "name_conflict+=1">> "!temp_set!"
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!img_file!" "!new_name!"
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
    set /a "fail_total=has_exif+other_prefix+no_time+name_conflict+rename_failed"
    echo 共计: !total! 个，成功: !ok_total! 个，失败: !fail_total! 个 & echo off
    echo 其中，重命名成功 !succeeded! 个，已符合规范 !already_ok! 个，已存在同名文件 !name_conflict! 个，时间获取失败 !no_time! 个，重命名失败 !rename_failed! 个，其他前缀跳过 !other_prefix! 个，带有拍摄时间: !has_exif! 个
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
        set /a "no_time=0"
        set /a "already_ok=0"
        set /a "name_conflict=0"
        set /a "rename_failed=0"
        set /a "has_exif=0"
        set /a "other_prefix=0"
        set "file_path=!img_file!"
        set "ext_filter=\.(jpg|png|bmp|gif)$"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "img_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!img_file!"

            REM 检查图片是否带有 EXIF 拍摄时间（Recorded_Date / Encoded_Date）
            set "creation_time="
            for /f "delims=" %%x in ('call "!mediainfo_path!" --Output^="General;%%Recorded_Date%%" "!img_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 图片 Recorded_Date 标记: "!creation_time!"
            )
            if "!creation_time!"=="" (
                for /f "delims=" %%x in ('call "!mediainfo_path!" --Output^="General;%%Encoded_Date%%" "!img_file!" 2^>nul') do (
                    set "creation_time=%%x"
                    echo 图片 Encoded_Date 标记: "!creation_time!"
                )
            )
            set "exif_time="
            if not "!creation_time!"=="" (
                for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($t) try { $s = $t -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3'; $dt = [DateTime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture); Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff') } catch {} } -t '!creation_time!'" 2^>nul') do (
                    set "exif_time=%%t"
                )
            )

            if not "!exif_time!"=="" (
                echo set /a "has_exif+=1">> "!temp_set!"
                echo 图片带有拍摄时间，跳过此文件
            ) else if /i "!base_name:~0,10!"=="Screenshot" (
                echo set /a "other_prefix+=1">> "!temp_set!"
                echo 文件名以 Screenshot 开头，跳过此文件
            ) else if /i "!base_name:~0,3!"=="IMG" (
                echo set /a "other_prefix+=1">> "!temp_set!"
                echo 文件名以 IMG 开头，跳过此文件
            ) else (
                set "formatted_time="
                for /f "delims=" %%t in ('powershell -NoProfile -Command "(Get-Item -LiteralPath $env:img_file).LastWriteTime.ToString('yyyyMMddHHmmss')" 2^>nul') do (
                    set "formatted_time=%%t"
                    echo 图片文件修改时间: "!formatted_time!"
                )

                if "!formatted_time!"=="" (
                    echo set /a "no_time+=1">> "!temp_set!"
                    echo 时间获取失败，跳过此文件
                ) else (
                    for /f "delims=" %%l in ('powershell -NoProfile -Command "$env:file_ext.ToLower()"') do (
                        set "lower_file_ext=%%l"
                    )
                    set "new_name=QQ截图!formatted_time!!lower_file_ext!"
                    echo 目标文件名: "!new_name!"
                    if /i "!img_file!"=="!file_dir!!new_name!" (
                        echo set /a "already_ok+=1">> "!temp_set!"
                        echo 文件名已符合规范，无需处理
                    ) else if exist "!file_dir!!new_name!" (
                        echo set /a "name_conflict+=1">> "!temp_set!"
                        echo 目标文件已存在，跳过此文件
                    ) else (
                        ren "!img_file!" "!new_name!"
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
        set /a "fail_total=has_exif+other_prefix+no_time+name_conflict+rename_failed"
        echo 共计: !total! 个，成功: !ok_total! 个，失败: !fail_total! 个 & echo off
        echo 其中，重命名成功 !succeeded! 个，已符合规范 !already_ok! 个，已存在同名文件 !name_conflict! 个，时间获取失败 !no_time! 个，重命名失败 !rename_failed! 个，其他前缀跳过 !other_prefix! 个，带有拍摄时间: !has_exif! 个
    ) else (
        echo 开始处理文件: "!img_file!"

        REM 检查图片是否带有 EXIF 拍摄时间（Recorded_Date / Encoded_Date）
        set "creation_time="
        for /f "delims=" %%x in ('call "!mediainfo_path!" --Output^="General;%%Recorded_Date%%" "!img_file!" 2^>nul') do (
            set "creation_time=%%x"
            echo 图片 Recorded_Date 标记: "!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('call "!mediainfo_path!" --Output^="General;%%Encoded_Date%%" "!img_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 图片 Encoded_Date 标记: "!creation_time!"
            )
        )
        set "exif_time="
        if not "!creation_time!"=="" (
            for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($t) try { $s = $t -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3'; $dt = [DateTime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture); Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff') } catch {} } -t '!creation_time!'" 2^>nul') do (
                set "exif_time=%%t"
            )
        )

        if not "!exif_time!"=="" (
            echo 图片带有拍摄时间，跳过此文件
        ) else if /i "!base_name:~0,10!"=="Screenshot" (
            echo 文件名以 Screenshot 开头，跳过此文件
        ) else if /i "!base_name:~0,3!"=="IMG" (
            echo 文件名以 IMG 开头，跳过此文件
        ) else (
            set "formatted_time="
            for /f "delims=" %%t in ('powershell -NoProfile -Command "(Get-Item -LiteralPath $env:img_file).LastWriteTime.ToString('yyyyMMddHHmmss')" 2^>nul') do (
                set "formatted_time=%%t"
                echo 图片文件修改时间: "!formatted_time!"
            )

            if "!formatted_time!"=="" (
                echo 时间获取失败，跳过此文件
            ) else (
                for /f "delims=" %%l in ('powershell -NoProfile -Command "$env:file_ext.ToLower()"') do (
                    set "lower_file_ext=%%l"
                )
                set "new_name=QQ截图!formatted_time!!lower_file_ext!"
                echo 目标文件名: "!new_name!"
                if /i "!img_file!"=="!file_dir!!new_name!" (
                    echo 文件名已符合规范，无需处理
                ) else if exist "!file_dir!!new_name!" (
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!img_file!" "!new_name!"
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
