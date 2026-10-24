@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，优化 Git 的全局默认设置' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '优化内容：不做换行符转换、文件名大小写敏感、中文路径不转义、日志和提交信息使用 UTF-8 编码' -ForegroundColor Green"
echo.



REM 检查 Git 组件
if exist "!script_dir!git.exe" (
    set "git_path=!script_dir!git.exe"
) else if exist "!cd!\git.exe" (
    set "git_path=!cd!\git.exe"
) else if exist "!script_dir!..\git.exe" (
    set "git_path=!script_dir!..\git.exe"
) else if exist "..\git.exe" (
    set "git_path=..\git.exe"
) else if exist "!ProgramFiles!\Git\bin\git.exe" (
    set "git_path=!ProgramFiles!\Git\bin\git.exe"
) else if exist "!ProgramFiles!\Git\cmd\git.exe" (
    set "git_path=!ProgramFiles!\Git\cmd\git.exe"
) else if exist "!ProgramFiles(x86)!\Git\bin\git.exe" (
    set "git_path=!ProgramFiles(x86)!\Git\bin\git.exe"
) else if exist "!ProgramFiles(x86)!\Git\cmd\git.exe" (
    set "git_path=!ProgramFiles(x86)!\Git\cmd\git.exe"
) else (
    set "git_path=git"
)
"!git_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Git 组件 & REM
    echo 请从 https://git-scm.com/downloads/win 下载，并完成安装 & REM
    "explorer.exe" "https://git-scm.com/downloads/win"
    echo.
    pause
    exit /b 1
)



echo 开始优化全局默认设置
echo.

"!git_path!" config --global core.autocrlf false
if !errorlevel! neq 0 (
    echo 错误：设置 core.autocrlf 失败
    echo.
    pause
    exit /b 1
)

"!git_path!" config --global core.safecrlf false
if !errorlevel! neq 0 (
    echo 错误：设置 core.safecrlf 失败
    echo.
    pause
    exit /b 1
)

"!git_path!" config --global core.ignorecase false
if !errorlevel! neq 0 (
    echo 错误：设置 core.ignorecase 失败
    echo.
    pause
    exit /b 1
)

"!git_path!" config --global core.quotepath false
if !errorlevel! neq 0 (
    echo 错误：设置 core.quotepath 失败
    echo.
    pause
    exit /b 1
)

"!git_path!" config --global i18n.logoutputencoding utf-8
if !errorlevel! neq 0 (
    echo 错误：设置 i18n.logoutputencoding 失败
    echo.
    pause
    exit /b 1
)

"!git_path!" config --global i18n.commitencoding utf-8
if !errorlevel! neq 0 (
    echo 错误：设置 i18n.commitencoding 失败
    echo.
    pause
    exit /b 1
)

echo 优化完成
echo.

echo 当前 Git 全局设置：
echo.
"!git_path!" config --global --list
echo.



echo.
pause
exit /b
