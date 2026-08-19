@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ %~nx0 ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '本脚本实现重复文件的搜索和清理功能，将 2 文件夹中已存在的文件从 1 文件夹中删除' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，按提示输入两个文件夹的路径' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '也可以选中两个文件夹，拖拽到此脚本上，自动识别处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '文件大小相同且内容完全一致时，将 1 中的重复文件删除到回收站' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "%~dp0"
)



setlocal disabledelayedexpansion
set "path1=%~1"
set "path2=%~2"
setlocal enabledelayedexpansion

:input_path1
if "!path1!"=="" (
    echo.
    echo 请输入要清理多余文件的文件夹
    set /p "path1="
)
if "!path1!"=="" (
    echo 输入不能为空，请重新输入
    goto input_path1
)
set "path1=!path1:"=!"
if "!path1:~-1!"=="\" set "path1=!path1:~0,-1!"
if not exist "!path1!\" (
    echo 错误：路径 1 不存在或不是文件夹："!path1!"，请重新输入
    set "path1="
    goto input_path1
)

:input_path2
if "!path2!"=="" (
    echo.
    echo 请输入作为参考的文件夹，仅用于文件比对
    set /p "path2="
)
if "!path2!"=="" (
    echo 输入不能为空，请重新输入
    goto input_path2
)
set "path2=!path2:"=!"
if "!path2:~-1!"=="\" set "path2=!path2:~0,-1!"
if not exist "!path2!\" (
    echo 错误：路径 2 不存在或不是文件夹："!path2!"，请重新输入
    set "path2="
    goto input_path2
)



echo.
echo 清理文件夹："!path1!"
echo 参考文件夹："!path2!"
echo.

set /a "total=0"
set /a "deleted=0"
set /a "failed=0"

for /f "delims=" %%f in ('dir /b /s /a-d "!path1!\*.*" 2^>nul') do (
    set /a "total+=1"
    set "matched=0"
    for %%i in ("%%f") do set "size1=%%~zi"
    for /f "delims=" %%g in ('dir /b /s /a-d "!path2!\*.*" 2^>nul') do (
        if !matched! equ 0 (
            for %%j in ("%%g") do set "size2=%%~zj"
            if "!size1!"=="!size2!" (
                fc /b "%%f" "%%g" > nul
                if !errorlevel! equ 0 (
                    set "matched=1"
                    set "file_to_delete=%%f"
                    powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:file_to_delete,'OnlyErrorDialogs','SendToRecycleBin')"
                    if exist "%%f" (
                        echo 删除失败："%%f"
                        echo 与之内容一致的文件："%%g"
                        set /a "failed+=1"
                    ) else (
                        echo 内容一致，已删除到回收站："%%f"
                        echo 与之内容一致的文件："%%g"
                        set /a "deleted+=1"
                    )
                )
            )
        )
    )
)

echo.
echo 处理完成
echo 共计：!total! 个文件，删除成功：!deleted! 个，删除失败：!failed! 个



echo.
pause
exit /b
