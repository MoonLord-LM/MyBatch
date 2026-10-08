@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，重启桌面进程 explorer.exe' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '重启前记录已打开的文件夹窗口，重启后自动重新打开' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '部分窗口可能无法恢复，窗口内的选中项等也无法恢复' -ForegroundColor Green"
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



set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"

echo 正在记录已打开的文件夹窗口
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "try {" ^
    "    $shell = New-Object -ComObject Shell.Application;" ^
    "}" ^
    "catch {" ^
    "    Write-Host '错误：获取资源管理器窗口列表失败' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$paths = @();" ^
    "$skip = 0;" ^
    "foreach ($w in @($shell.Windows())) {" ^
    "    try {" ^
    "        $url = $w.LocationURL;" ^
    "        if (-not $url) {" ^
    "            $skip++;" ^
    "            Write-Host ('忽略空路径：' + $w.LocationName) -ForegroundColor Yellow;" ^
    "            continue;" ^
    "        }" ^
    "        if ($url -match '^file:///') {" ^
    "            $p = $url.Substring(8);" ^
    "        }" ^
    "        elseif ($url -match '^file://') {" ^
    "            $p = '\' + $url.Substring(7);" ^
    "        }" ^
    "        else {" ^
    "            $skip++;" ^
    "            Write-Host ('忽略异常协议路径：' + $url) -ForegroundColor Yellow;" ^
    "            continue;" ^
    "        }" ^
    "        $path = [Uri]::UnescapeDataString($p) -replace '/', '\';" ^
    "        $paths += $path;" ^
    "        Write-Host ('文件夹窗口：' + $path);" ^
    "    }" ^
    "    catch {" ^
    "        $skip++;" ^
    "    }" ^
    "}" ^
    "[Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null;" ^
    "if ($paths.Count -gt 0) {" ^
    "    Set-Content -LiteralPath $env:temp_list -Value $paths -Encoding UTF8;" ^
    "};" ^
    "Write-Host ('已记录 ' + $paths.Count + ' 个文件夹窗口，跳过 ' + $skip + ' 个非文件夹窗口');"
if !errorlevel! neq 0 (
    if exist "!temp_list!" ( del /f /q "!temp_list!" )
    echo 错误：记录文件夹窗口失败，未重启桌面进程
    echo.
    pause
    exit /b 1
)
echo.

echo 正在重启桌面进程
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$winlogon = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue;" ^
    "$autoRestart = 0;" ^
    "if ($winlogon -and $winlogon.Shell -eq 'explorer.exe' -and $winlogon.AutoRestartShell -eq 1) {" ^
    "    $autoRestart = 1;" ^
    "};" ^
    "$old = @(Get-Process -Name explorer -ErrorAction SilentlyContinue | ForEach-Object { $_.Id });" ^
    "if ($old.Count -gt 0) {" ^
    "    try {" ^
    "        Stop-Process -Id $old -Force -ErrorAction Stop;" ^
    "    }" ^
    "    catch {" ^
    "        Write-Host '错误：结束桌面进程失败' -ForegroundColor Red;" ^
    "        exit 1;" ^
    "    };" ^
    "    $n = 0;" ^
    "    while (@(Get-Process -Id $old -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq 'explorer' }).Count -gt 0) {" ^
    "        Start-Sleep -Milliseconds 200;" ^
    "        $n++;" ^
    "        if ($n -gt 50) {" ^
    "            Write-Host '错误：等待桌面进程结束超时' -ForegroundColor Red;" ^
    "            exit 1;" ^
    "        }" ^
    "    };" ^
    "    if ($autoRestart -eq 1) {" ^
    "        Write-Host '系统已设置自动重启桌面进程，等待其自动重启';" ^
    "        $n = 0;" ^
    "        while (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {" ^
    "            Start-Sleep -Milliseconds 200;" ^
    "            $n++;" ^
    "            if ($n -gt 50) {" ^
    "                Write-Host '等待系统自动重启桌面进程超时，执行主动启动';" ^
    "                break;" ^
    "            }" ^
    "        };" ^
    "    };" ^
    "};" ^
    "$new = @(Get-Process -Name explorer -ErrorAction SilentlyContinue | ForEach-Object { $_.Id });" ^
    "if ($new.Count -eq 0) {" ^
    "    try {" ^
    "        Start-Process explorer.exe -ErrorAction Stop;" ^
    "    }" ^
    "    catch {" ^
    "        Write-Host '错误：启动桌面进程失败' -ForegroundColor Red;" ^
    "        exit 1;" ^
    "    };" ^
    "    $n = 0;" ^
    "    while (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {" ^
    "        Start-Sleep -Milliseconds 200;" ^
    "        $n++;" ^
    "        if ($n -gt 50) {" ^
    "            Write-Host '错误：等待桌面进程启动超时' -ForegroundColor Red;" ^
    "            exit 1;" ^
    "        }" ^
    "    };" ^
    "};" ^
    "Start-Sleep -Milliseconds 800;"
if !errorlevel! neq 0 (
    if exist "!temp_list!" ( del /f /q "!temp_list!" )
    echo 错误：桌面进程重启失败，请检查报错信息
    echo.
    pause
    exit /b 1
)
echo.

echo 正在恢复已打开的文件夹窗口
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$paths = @(Get-Content -Encoding UTF8 -LiteralPath $env:temp_list -ErrorAction SilentlyContinue | Where-Object { $_ -ne '' });" ^
    "$ok = 0;" ^
    "$skip = 0;" ^
    "foreach ($p in $paths) {" ^
    "    if (Test-Path -LiteralPath $p -PathType Container) {" ^
    "        $q = $p;" ^
    "        if ($q.Length -gt 3) { $q = $q.TrimEnd('\') };" ^
    "        try {" ^
    "            Start-Process explorer.exe -ArgumentList ('\"' + $q + '\"');" ^
    "            $ok++;" ^
    "        }" ^
    "        catch {" ^
    "            $skip++;" ^
    "            Write-Host ('异常路径：' + $p) -ForegroundColor Yellow;" ^
    "        };" ^
    "        Start-Sleep -Milliseconds 200;" ^
    "    }" ^
    "    else {" ^
    "        $skip++;" ^
    "        Write-Host ('异常路径：' + $p) -ForegroundColor Yellow;" ^
    "    }" ^
    "}" ^
    "Write-Host ('已恢复 ' + $ok + ' 个文件夹窗口，跳过 ' + $skip + ' 个异常路径');"
if exist "!temp_list!" ( del /f /q "!temp_list!" )
echo.

echo 已完成重启



echo.
pause
exit /b
