@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo 本脚本实现重复文件的搜索和清理功能，将 B 文件夹中已存在的文件从 A 文件夹中删除
echo.

echo 请输入路径 A (要清理的文件夹，执行删除操作):
set /p pathA=
echo 请输入路径 B (作为参考的文件夹，仅用于文件比对):
set /p pathB=

if not exist "!pathA!\" (
    echo 错误：路径 A 不存在或不是文件夹！
    pause
    exit
)

if not exist "!pathB!\" (
    echo 错误：路径 B 不存在或不是文件夹！
    pause
    exit
)

echo.
echo 开始处理
echo "!pathA!"
echo "!pathB!"
echo.

for /f "delims=" %%f in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath $env:pathA -File -Recurse | ForEach-Object { $_.FullName }"') do (
    echo 正在处理: "%%f"
    if exist "%%f" (
        set "sizeA=%%~zf"
        for /f "delims=" %%g in ('es.exe -path "!pathB!" /a-d size:^=!sizeA!') do (
            echo "%%g"
            if exist "%%g" (
                echo 文件大小相同 - !sizeA!
                echo %%f
                echo %%g

                fc /b "%%f" "%%g" >nul
                if !errorlevel! equ 0 (
                    echo 文件内容相同，执行删除
                    set "file_to_delete=%%f"
                    powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:file_to_delete,'OnlyErrorDialogs','SendToRecycleBin')"
                ) else (
                    echo 文件内容不同，跳过
                )
                echo.
            )
        )
    )
)

echo.
echo 处理完成

pause
exit
