@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，清理 Chrome 浏览器的组织管理策略的注册表项' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '清理后浏览器将不再提示由组织管理，可在 chrome://policy/ 页面确认' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '参考：https://www.zhihu.com/question/318527439' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

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
    exit /b
)



echo 开始清理系统级策略
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome" >nul 2>&1
if !errorlevel! neq 0 (
    echo 未发现系统级策略，无需清理
) else (
    reg delete /f "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome" >nul 2>&1
    if !errorlevel! neq 0 (
        echo 错误：系统级策略删除失败，请检查报错信息
        echo.
        pause
        exit /b 1
    )
    echo 已删除系统级策略注册表项
)
echo.

echo 正在清理用户级策略
reg query "HKEY_CURRENT_USER\SOFTWARE\Policies\Google\Chrome" >nul 2>&1
if !errorlevel! neq 0 (
    echo 未发现用户级策略，无需清理
) else (
    reg delete /f "HKEY_CURRENT_USER\SOFTWARE\Policies\Google\Chrome" >nul 2>&1
    if !errorlevel! neq 0 (
        echo 错误：用户级策略删除失败，请检查报错信息
        echo.
        pause
        exit /b 1
    )
    echo 已删除用户级策略注册表项
)
echo.
echo 清理完成，请重启浏览器后，查看 chrome://policy/ 页面，确认提示已消失



echo.
pause
exit /b
