@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
set "param1=%~1" & set "param1_path=%~f1" & set "param1_dir=%~dp1" & set "param1_name=%~n1" & set "param1_ext=%~x1" & set "param1_name_ext=%~nx1"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '优化 Git 的二进制仓库设置' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '优化内容：原始保存的大文件阈值 100MB、关闭压缩处理' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '效果说明：仓库体积会变大，但是对于大文件的处理速度会变快' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '双击运行时，自动扫描当前文件夹' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '拖拽文件夹到此脚本上时，则处理拖入的文件夹；不支持拖入单个文件' -ForegroundColor Green"
echo.



REM 检查 Git 组件
"git.exe" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Git 组件 & REM
    echo 请从 https://git-scm.com/install/windows 下载，并完成安装 & REM
    "explorer.exe" "https://git-scm.com/install/windows"
    echo.
    pause
    exit /b 1
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
        exit /b 1
    )
    if exist "!param1!\" (
        echo 开始处理文件夹："!param1!"
        set "working_dir=!param1!"
        echo.
    ) else (
        echo 错误：不支持拖入单个文件，请拖入文件夹或双击运行
        echo.
        pause
        exit /b 1
    )
)

if not exist "!working_dir!\.git" (
    echo 错误：不是 Git 仓库，未找到 .git 文件夹："!working_dir!"
    echo.
    pause
    exit /b 1
)



echo 开始设置仓库设置
echo.

"git.exe" -C "!working_dir!" config --local core.bigFileThreshold 100m
if !errorlevel! neq 0 (
    echo 错误：设置 core.bigFileThreshold 失败
    echo.
    pause
    exit /b 1
)

"git.exe" -C "!working_dir!" config --local core.compression 0
if !errorlevel! neq 0 (
    echo 错误：设置 core.compression 失败
    echo.
    pause
    exit /b 1
)

"git.exe" -C "!working_dir!" config --local core.looseCompression 0
if !errorlevel! neq 0 (
    echo 错误：设置 core.looseCompression 失败
    echo.
    pause
    exit /b 1
)

"git.exe" -C "!working_dir!" config --local pack.compression 0
if !errorlevel! neq 0 (
    echo 错误：设置 pack.compression 失败
    echo.
    pause
    exit /b 1
)

echo 设置完成
echo.



echo 当前 Git 仓库设置：
echo.
"git.exe" -C "!working_dir!" config --local --list
echo.



echo.
pause
exit /b
