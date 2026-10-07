@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，关闭磁盘显示红色的机制' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '避免大容量磁盘还有较大空间时，就显示为红色，影响体验' -ForegroundColor Green"
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



echo 正在处理 TileInfo
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$driveKey = 'HKLM:\SOFTWARE\Classes\Drive';" ^
    "try {" ^
    "    $old = (Get-ItemProperty -LiteralPath $driveKey -Name 'TileInfo' -ErrorAction Stop).TileInfo;" ^
    "    Write-Host ('当前 TileInfo 值为 ' + $old);" ^
    "}" ^
    "catch {" ^
    "    Write-Host '错误：读取注册表失败' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "if ($old -match '\*?System\.PercentFull;') {" ^
    "    $new = $old -replace '\*?System\.PercentFull;', '';" ^
    "    try {" ^
    "        Set-ItemProperty -LiteralPath $driveKey -Name 'TileInfo' -Type String -Value $new -ErrorAction Stop;" ^
    "    }" ^
    "    catch {" ^
    "        Write-Host '错误：写入注册表失败' -ForegroundColor Red;" ^
    "        exit 1;" ^
    "    };" ^
    "    Write-Host ('已删除 System.PercentFull 值，当前 TileInfo 值为 ' + $new);" ^
    "}" ^
    "else {" ^
    "    Write-Host '未发现 System.PercentFull 值，无需处理';" ^
    "};"
if !errorlevel! neq 0 (
    echo 错误：TileInfo 处理失败，请检查上面的报错信息
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
echo.

echo 正在处理 PreviewDetails
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$driveKey = 'HKLM:\SOFTWARE\Classes\Drive';" ^
    "try {" ^
    "    $old = (Get-ItemProperty -LiteralPath $driveKey -Name 'PreviewDetails' -ErrorAction Stop).PreviewDetails;" ^
    "    Write-Host ('当前 PreviewDetails 值为 ' + $old);" ^
    "}" ^
    "catch {" ^
    "    Write-Host '错误：读取注册表失败' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "if ($old -match '\*?System\.PercentFull;') {" ^
    "    $new = $old -replace '\*?System\.PercentFull;', '';" ^
    "    try {" ^
    "        Set-ItemProperty -LiteralPath $driveKey -Name 'PreviewDetails' -Type String -Value $new -ErrorAction Stop;" ^
    "    }" ^
    "    catch {" ^
    "        Write-Host '错误：写入注册表失败' -ForegroundColor Red;" ^
    "        exit 1;" ^
    "    };" ^
    "    Write-Host ('已删除 System.PercentFull 值，当前 PreviewDetails 值为 ' + $new);" ^
    "}" ^
    "else {" ^
    "    Write-Host '未发现 System.PercentFull 值，无需处理';" ^
    "};"
if !errorlevel! neq 0 (
    echo 错误：PreviewDetails 处理失败，请检查上面的报错信息
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
echo.

echo 修改完成，需要重启桌面进程 explorer.exe 才会生效



echo.
pause
endlocal & endlocal & exit /b
