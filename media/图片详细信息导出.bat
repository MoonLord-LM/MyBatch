@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '图片详细参数信息。导出为同名的 json 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的图片文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个图片文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)

REM 优先使用脚本所在文件夹中的 MediaInfo 组件
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
    set /a "json_exist=0"
    set /a "parse_failed=0"
    set "file_path=!cd!"
    set "ext_filter=\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "img_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        setlocal enabledelayedexpansion

        echo 正在处理: "!img_file!"
        set "json_file=!file_dir!!base_name!.json"
        if exist "!json_file!" (
            echo set /a "json_exist+=1">> "!temp_set!"
            echo 已存在: "!json_file!"，跳过此文件
        ) else (
            "!mediainfo_path!" --Output=JSON "!img_file!" > "!json_file!"
            if !errorlevel! neq 0 (
                echo set /a "parse_failed+=1">> "!temp_set!"
                if exist "!json_file!" ( del /f /q "!json_file!" )
                echo 图片解析报错
            ) else (
                echo set /a "succeeded+=1">> "!temp_set!"
                echo 保存文件: "!json_file!"
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
    set /a "fail_total=json_exist+parse_failed"
    echo 共计: !total! 个，成功: !ok_total! 个，失败: !fail_total! 个 & echo off
    echo 其中，导出成功 !succeeded! 个，解析报错 !parse_failed! 个，json 文件已存在 !json_exist! 个
) else (
    setlocal disabledelayedexpansion
    set "img_file=%~1"
    set "file_dir=%~dp1"
    set "base_name=%~n1"
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
        set /a "json_exist=0"
        set /a "parse_failed=0"
        set "file_path=!img_file!"
        set "ext_filter=\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$"
        for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
            setlocal disabledelayedexpansion
            set "img_file=%%f"
            set "file_dir=%%~dpf"
            set "base_name=%%~nf"
            setlocal enabledelayedexpansion

            echo 正在处理: "!img_file!"
            set "json_file=!file_dir!!base_name!.json"
            if exist "!json_file!" (
                echo set /a "json_exist+=1">> "!temp_set!"
                echo 已存在: "!json_file!"，跳过此文件
            ) else (
                "!mediainfo_path!" --Output=JSON "!img_file!" > "!json_file!"
                if !errorlevel! neq 0 (
                    echo set /a "parse_failed+=1">> "!temp_set!"
                    if exist "!json_file!" ( del /f /q "!json_file!" )
                    echo 图片解析报错
                ) else (
                    echo set /a "succeeded+=1">> "!temp_set!"
                    echo 保存文件: "!json_file!"
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
        set /a "fail_total=json_exist+parse_failed"
        echo 共计: !total! 个，成功: !ok_total! 个，失败: !fail_total! 个 & echo off
        echo 其中，导出成功 !succeeded! 个，解析报错 !parse_failed! 个，json 文件已存在 !json_exist! 个
    ) else (
        echo 开始处理文件: "!img_file!"
        set "json_file=!file_dir!!base_name!.json"
        if exist "!json_file!" (
            echo 已存在: "!json_file!"，跳过此文件
        ) else (
            "!mediainfo_path!" --Output=JSON "!img_file!" > "!json_file!"
            if !errorlevel! neq 0 (
                if exist "!json_file!" ( del /f /q "!json_file!" )
                echo 图片解析报错
            ) else (
                echo 保存文件: "!json_file!"
            )
        )
    )

    endlocal
    endlocal
)



echo.
pause
exit /b
