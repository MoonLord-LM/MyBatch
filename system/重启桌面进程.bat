@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，重启桌面进程 explorer.exe' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '重启前记录已打开的文件夹窗口，重启后自动重新打开' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '部分窗口可能无法恢复，窗口内的文件夹选中项等也无法恢复' -ForegroundColor Green"
echo.



set "temp_list=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!temp_list!"

echo 正在记录已打开的文件夹窗口
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$shell = New-Object -ComObject Shell.Application;" ^
    "$paths = @();" ^
    "foreach ($w in @($shell.Windows())) {" ^
    "    try {" ^
    "        $u = $w.LocationURL;" ^
    "        if (-not $u) {" ^
    "            continue;" ^
    "        }" ^
    "        if ($u -match '^file:///') {" ^
    "            $p = $u.Substring(8);" ^
    "        }" ^
    "        elseif ($u -match '^file://') {" ^
    "            $p = '\' + $u.Substring(7);" ^
    "        }" ^
    "        else {" ^
    "            continue;" ^
    "        }" ^
    "        $path = [Uri]::UnescapeDataString($p) -replace '/', '\';" ^
    "        $paths += $path;" ^
    "        Write-Host ('文件夹窗口：' + $path);" ^
    "    } catch { }" ^
    "}" ^
    "[Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null;" ^
    "if ($paths.Count -gt 0) {" ^
    "        Set-Content -LiteralPath $env:temp_list -Value $paths -Encoding UTF8;" ^
    "};" ^
    "Write-Host ('已记录 ' + $paths.Count + ' 个文件夹窗口');"
echo.

echo 正在重启桌面进程
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue;" ^
    "while (Get-Process -Name explorer -ErrorAction SilentlyContinue) {" ^
    "    Start-Sleep -Milliseconds 200" ^
    "};" ^
    "Start-Process explorer.exe;" ^
    "while (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {" ^
    "    Start-Sleep -Milliseconds 200" ^
    "};"
echo.

echo 正在恢复已打开的文件夹窗口
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$paths = @(Get-Content -Encoding UTF8 -LiteralPath $env:temp_list -ErrorAction SilentlyContinue | Where-Object { $_ -ne '' });" ^
    "$ok = 0;" ^
    "$skip = 0;" ^
    "foreach ($p in $paths) {" ^
    "    if (Test-Path -LiteralPath $p -PathType Container) {" ^
    "        Start-Process explorer.exe -ArgumentList $p;" ^
    "        $ok++;" ^
    "    }" ^
    "    else {" ^
    "        $skip++;" ^
    "    }" ^
    "}" ^
    "Write-Host ('已恢复 ' + $ok + ' 个文件夹窗口，跳过 ' + $skip + ' 个无效路径');"
if exist "!temp_list!" ( del /f /q "!temp_list!" )
echo.

echo 已完成重启



echo.
pause
endlocal & endlocal & exit /b
