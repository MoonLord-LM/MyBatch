@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



:: 扫描当前目录下的 mkv、flv、mov、vob 文件，自动转换为 h264 编码的 mp4 格式



if /i "%cd%"=="%SystemRoot%\System32" (
    echo 检测到使用右键的"以管理员权限运行"，切换到脚本所在目录 & echo.
    cd /d "%~dp0"
)

set "processed=0"
set "failed=0"
set "skipped=0"

set "convert=-vf yadif -c:v libx264 -preset veryslow -crf 18 -c:a aac -b:a 320k"

for %%e in (mkv flv mov vob) do (
    for %%f in (*.%%e) do (
        setlocal disabledelayedexpansion
        set "file_name=%%f"
        set "base_name=%%~nf"
        set "ext_name=%%~xf"
        setlocal enabledelayedexpansion

        echo --------------------------------------------------
        echo 正在检查: !file_name!

        if exist "!base_name!.mp4" (
            echo 跳过，已存在同名的 mp4 文件
            set /a "skipped+=1"
        ) else (
            echo 开始转换: !file_name! -^> !base_name!.mp4
            ffmpeg.exe -i "!file_name!" !convert! -map_metadata 0 -movflags +faststart "!base_name!.mp4"
            if errorlevel 1 (
                echo 转换失败: !file_name!
                set /a "failed+=1"
            ) else (
                echo 转换成功: !base_name!.mp4
                set /a "processed+=1"
            )
        )
        echo.
        endlocal
        endlocal
    )
)



echo.
echo ==================================================
echo 扫描完成
echo 成功: !processed!
echo 失败: !failed!
echo 跳过: !skipped!
echo ==================================================



echo.
pause
exit /b

