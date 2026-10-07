@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，修改磁盘显示红色的阈值为 2%% 的剩余空间' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '避免大容量磁盘还有很大空间时，就显示为红色，影响体验' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '修改设置后，需要重启桌面进程 explorer.exe 才会生效' -ForegroundColor Green"
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
        powershell -NoProfile -Command "Write-Host '获取系统管理员权限失败' -ForegroundColor Green"
        echo.
        pause
        exit /b 1
    )
    exit /b
)



echo 正在修改注册表
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer';" ^
    "try {" ^
    "    Set-ItemProperty -Path $path -Name 'PercentFull' -Type DWord -Value 2 -ErrorAction Stop;" ^
    "}" ^
    "catch {" ^
    "    Write-Host '错误：注册表修改失败' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$percentFull = (Get-ItemProperty -LiteralPath $path -Name 'PercentFull').PercentFull;" ^
    "Write-Host ('当前磁盘显示红色的阈值为 ' + $percentFull + '%%');"
if !errorlevel! neq 0 (
    echo 错误：注册表修改失败，请检查报错信息
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
echo.

echo 修改完成，重启桌面进程后生效



echo.
pause
endlocal & endlocal & exit /b
