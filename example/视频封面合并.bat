@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo =================================================
echo 正在扫描当前目录下的 MP4 文件...
echo =================================================

set "processed=0"

:: 遍历当前目录下的所有 mp4 文件
for %%v in (*.mp4) do (
    set "base_name=%%~nv"
    set "cover_file="
    
    echo 检查: %%v
    
    :: 优先检查 PNG 格式
    if exist "!base_name!.png" (
        set "cover_file=!base_name!.png"
    ) else if exist "!base_name!.jpg" (
        set "cover_file=!base_name!.jpg"
    )
    
    if defined cover_file (
        echo 找到封面: !cover_file!
        ffmpeg -i "%%v" -i "!cover_file!" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "temp_%%v" -hide_banner -loglevel error
        
        if !errorlevel! equ 0 (
            del /f /q "%%v" > nul
            ren "temp_%%v" "%%v" > nul
            echo 封面设置成功: %%v
            set /a "processed+=1"
        ) else (
            echo 封面设置失败: %%v
            if exist "temp_%%v" del /f /q "temp_%%v" > nul
        )
    ) else (
        echo 未找到匹配的封面: !base_name!.{png,jpg}
    )
)

echo.
echo =================================================
if %processed% equ 0 (
    echo 未成功处理任何文件
) else (
    echo 成功为 %processed% 个文件设置封面
)
echo =================================================

pause
exit
