@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将图片按 EXIF 的拍摄时间，重命名为 IMG_YYYYMMDD_HHMMSS_fff 格式，默认使用系统时区' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前目录下所有的图片文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个图片文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

MediaInfo --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误: 缺少 MediaInfo 组件
    echo 请从 https://mediaarea.net/en/MediaInfo 下载
    "explorer.exe" "https://mediaarea.net/en/MediaInfo"
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
    for /r %%f in (*.jpg *.jpeg *.png *.webp *.bmp *.gif *.tif *.tiff *.heic *.heif *.avif) do (
        setlocal disabledelayedexpansion
        set "img_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!img_file!"
        set "creation_time="
        for /f "delims=" %%x in ('MediaInfo --Output^="General;%%Recorded_Date%%" "!img_file!" 2^>nul') do (
            set "creation_time=%%x"
            echo 图片 Recorded_Date 标记: "!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('MediaInfo --Output^="General;%%Encoded_Date%%" "!img_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 图片 Encoded_Date 标记: "!creation_time!"
            )
        )
        set "formatted_time="
        if not "!creation_time!"=="" (
            for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($t) try { $s = $t -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3'; $dt = [DateTime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture); Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff') } catch {} } -t '!creation_time!'" 2^>nul') do (
                set "formatted_time=%%t"
            )
        )

        if "!formatted_time!"=="" (
            echo set /a "skipped+=1">> "!temp_set!"
            echo 图片 EXIF 拍摄时间获取失败，跳过此文件
        ) else (
            for /f "delims=" %%l in ('powershell -NoProfile -Command "$env:file_ext.ToLower()"') do set "lower_file_ext=%%l"
            set "new_name=IMG_!formatted_time!!lower_file_ext!"
            echo 目标文件名: "!new_name!"
            if /i "!img_file!"=="!file_dir!!new_name!" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 文件名已符合规范，无需处理
            ) else if exist "!file_dir!!new_name!" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 目标文件已存在，跳过此文件
            ) else (
                ren "!img_file!" "!new_name!"
                if !errorlevel! equ 0 (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 重命名成功
                ) else (
                    echo set /a "failed+=1">> "!temp_set!"
                    echo 重命名失败
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
        set /a "skipped=0"
        set /a "failed=0"
        for /r "!img_file!" %%f in (*.jpg *.jpeg *.png *.webp *.bmp *.gif *.tif *.tiff *.heic *.heif *.avif) do (
            setlocal disabledelayedexpansion
            set "img_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            set "file_ext=%%~xf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!img_file!"
            set "creation_time="
            for /f "delims=" %%x in ('MediaInfo --Output^="General;%%Recorded_Date%%" "!img_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 图片 Recorded_Date 标记: "!creation_time!"
            )
            if "!creation_time!"=="" (
                for /f "delims=" %%x in ('MediaInfo --Output^="General;%%Encoded_Date%%" "!img_file!" 2^>nul') do (
                    set "creation_time=%%x"
                    echo 图片 Encoded_Date 标记: "!creation_time!"
                )
            )
            set "formatted_time="
            if not "!creation_time!"=="" (
                for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($t) try { $s = $t -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3'; $dt = [DateTime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture); Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff') } catch {} } -t '!creation_time!'" 2^>nul') do (
                    set "formatted_time=%%t"
                )
            )

            if "!formatted_time!"=="" (
                echo set /a "skipped+=1">> "!temp_set!"
                echo 图片 EXIF 拍摄时间获取失败，跳过此文件
            ) else (
                for /f "delims=" %%l in ('powershell -NoProfile -Command "$env:file_ext.ToLower()"') do set "lower_file_ext=%%l"
                set "new_name=IMG_!formatted_time!!lower_file_ext!"
                echo 目标文件名: "!new_name!"
                if /i "!img_file!"=="!file_dir!!new_name!" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 文件名已符合规范，无需处理
                ) else if exist "!file_dir!!new_name!" (
                    echo set /a "skipped+=1">> "!temp_set!"
                    echo 目标文件已存在，跳过此文件
                ) else (
                    ren "!img_file!" "!new_name!"
                    if !errorlevel! equ 0 (
                        echo set /a "succeeded+=1">> "!temp_set!"
                        echo 重命名成功
                    ) else (
                        echo set /a "failed+=1">> "!temp_set!"
                        echo 重命名失败
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
        echo 开始处理文件: "!img_file!"
        set "creation_time="
        for /f "delims=" %%x in ('MediaInfo --Output^="General;%%Recorded_Date%%" "!img_file!" 2^>nul') do (
            set "creation_time=%%x"
            echo 图片 Recorded_Date 标记: "!creation_time!"
        )
        if "!creation_time!"=="" (
            for /f "delims=" %%x in ('MediaInfo --Output^="General;%%Encoded_Date%%" "!img_file!" 2^>nul') do (
                set "creation_time=%%x"
                echo 图片 Encoded_Date 标记: "!creation_time!"
            )
        )
        set "formatted_time="
        if not "!creation_time!"=="" (
            for /f "delims=" %%t in ('powershell -NoProfile -Command "& {param($t) try { $s = $t -replace '(\d{4}):(\d{2}):(\d{2})', '$1-$2-$3'; $dt = [DateTime]::Parse($s, [Globalization.CultureInfo]::InvariantCulture); Write-Output $dt.ToString('yyyyMMdd_HHmmss_fff') } catch {} } -t '!creation_time!'" 2^>nul') do (
                set "formatted_time=%%t"
            )
        )

        if "!formatted_time!"=="" (
            echo 图片 EXIF 拍摄时间获取失败，跳过此文件
        ) else (
            for /f "delims=" %%l in ('powershell -NoProfile -Command "$env:file_ext.ToLower()"') do set "lower_file_ext=%%l"
            set "new_name=IMG_!formatted_time!!lower_file_ext!"
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

    endlocal
    endlocal
)



echo.
pause
exit /b
