@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '将图片的详细参数信息，导出为同名的 json 文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动递归扫描和处理当前文件夹下所有的图片文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽单个图片文件到此脚本上时，则只处理该文件；拖拽文件夹时，则递归处理其中所有文件' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '支持的格式为 jpg jpeg png webp bmp gif tif tiff heic heif avif' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 MediaInfo 组件
if exist "!script_dir!MediaInfo.exe" (
    set "mediainfo_path=!script_dir!MediaInfo.exe"
) else if exist "!cd!\MediaInfo.exe" (
    set "mediainfo_path=!cd!\MediaInfo.exe"
) else if exist "!script_dir!..\MediaInfo.exe" (
    set "mediainfo_path=!script_dir!..\MediaInfo.exe"
) else if exist "..\MediaInfo.exe" (
    set "mediainfo_path=..\MediaInfo.exe"
) else (
    set "mediainfo_path=mediainfo"
)
"!mediainfo_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 MediaInfo 组件
    echo 请从 https://mediaarea.net/en/MediaInfo 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://mediaarea.net/en/MediaInfo"
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

        set "json_file=!file_dir!!base_name!!file_ext!.json"
        if exist "!json_file!" (
            echo 已存在："!json_file!"，跳过此文件
        ) else (
            "!mediainfo_path!" --Output=JSON "!param1!" > "!json_file!"
            if !errorlevel! neq 0 (
                if exist "!json_file!" ( del /f /q "!json_file!" )
                echo 图片解析报错
            ) else (
                echo 保存文件："!json_file!"
            )
        )
    )
)

if not "!working_dir!" == "" (
    REM 为了实现变量的跨域传递，将变量赋值语句保存到 "!temp_set!" 临时文件
    set "temp_set=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp.bat" & type nul > "!temp_set!"

    set /a "total=0"
    set /a "succeeded=0"
    set /a "json_exist=0"
    set /a "parse_failed=0"
    set "file_path=!working_dir!"
    set "ext_filter=\.(jpg|jpeg|png|webp|bmp|gif|tif|tiff|heic|heif|avif)$"
    for /f "delims=" %%f in ('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-ChildItem -LiteralPath $env:file_path -File -Force -Recurse | Where-Object { $_.Extension -match $env:ext_filter } | ForEach-Object { $_.FullName }"') do (
        setlocal disabledelayedexpansion
        set "img_file=%%f"
        set "file_dir=%%~dpf"
        set "base_name=%%~nf"
        set "file_ext=%%~xf"
        setlocal enabledelayedexpansion

        echo 处理文件："!img_file!"
        set "json_file=!file_dir!!base_name!!file_ext!.json"
        if exist "!json_file!" (
            echo set /a "json_exist+=1">> "!temp_set!"
            echo 已存在："!json_file!"，跳过此文件
        ) else (
            "!mediainfo_path!" --Output=JSON "!img_file!" > "!json_file!"
            if !errorlevel! neq 0 (
                echo set /a "parse_failed+=1">> "!temp_set!"
                if exist "!json_file!" ( del /f /q "!json_file!" )
                echo 图片解析报错
            ) else (
                echo set /a "succeeded+=1">> "!temp_set!"
                echo 保存文件："!json_file!"
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
    echo 共计：!total! 个，成功：!ok_total! 个，失败：!fail_total! 个 & REM
    echo 其中，导出成功 !succeeded! 个，解析报错 !parse_failed! 个，json 文件已存在 !json_exist! 个
)



echo.
pause
endlocal & endlocal & exit /b
