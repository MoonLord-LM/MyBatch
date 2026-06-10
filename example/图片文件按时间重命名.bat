@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 将图片按最后修改时间重命名为 IMG_yyyyMMdd_HHmmss.jpg 的格式

for %%f in (*.jpg *.jpeg *.png *.webp) do (
    set "file_name=%%f"

    echo 处理文件："!file_name!"

    set "formatted_time="
    for /f "delims=" %%t in ('powershell -NoProfile -Command "(Get-Item -LiteralPath '%%f').LastWriteTime.ToString('yyyyMMdd_HHmmss')"') do (
        set "formatted_time=%%t"
    )

    if not defined formatted_time (
        echo 警告：获取创建时间失败，跳过此文件
    ) else (
        set "ext=%%~xf"
        set "new_name=IMG_!formatted_time!!ext!"

        echo 创建时间："!formatted_time!"
        echo 目标文件名："!new_name!"

        if /i "!file_name!"=="!new_name!" (
            echo 目标文件名与原文件名相同，无需处理
        ) else if exist "!new_name!" (
            echo 警告：目标文件已存在，跳过此文件
        ) else (
            ren "!file_name!" "!new_name!"
            if !errorlevel! equ 0 (
                echo 重命名成功
            ) else (
                echo 警告：重命名失败
            )
        )
    )

    echo.
)

pause
exit
