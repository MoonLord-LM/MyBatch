@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '用记事本打开系统 hosts 文件，编辑保存后自动刷新 DNS 缓存' -ForegroundColor Green"
echo.



REM 获取系统管理员权限
net file >nul 2>&1
if !errorlevel! equ 0 (
    powershell -NoProfile -Command "Write-Host '已获取系统管理员权限' -ForegroundColor Green"
    echo.
) else (
    powershell -NoProfile -Command "Write-Host '需要系统管理员权限，请确认……' -ForegroundColor Green"
    echo.
    setlocal disabledelayedexpansion
    powershell start -verb "RunAs" "%~f0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" >nul 2>&1
    endlocal
    if !errorlevel! neq 0 (
        powershell -NoProfile -Command "Write-Host '错误：获取系统管理员权限失败' -ForegroundColor Red"
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)



set "hosts_file=!SystemRoot!\System32\drivers\etc\hosts"
if not exist "!hosts_file!" (
    echo 错误：未找到系统 hosts 文件："!hosts_file!"
    echo.
    pause
    exit /b 1
)



echo 正在刷新 DNS 缓存
ipconfig /flushdns
echo.

echo 正在打开系统 hosts 文件，请编辑并保存后关闭记事本
notepad "!hosts_file!"
echo.

echo 正在刷新 DNS 缓存，使修改生效
ipconfig /flushdns
echo.



echo.
pause
exit /b 0
