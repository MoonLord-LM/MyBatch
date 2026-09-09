@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '自动获取本机所在局域网的 IP，并发扫描同网段 2-255 的地址，列出在线机器' -ForegroundColor Green"
echo.



REM 自动获取本机 IP：取存在默认网关（能出网）的活动网卡的 IPv4 地址
for /f "delims=" %%a in ('powershell -NoProfile -Command "try { (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress } catch { }"') do set "local_ip=%%a"

if "!local_ip!"=="" (
    echo 获取本机 IP 失败，请检查网络连接后重试 & REM
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

echo 本机 IP：!local_ip!
echo.



echo 正在并发扫描局域网（约 0.5 秒）...
echo.

powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$local_ip = $env:local_ip;" ^
    "$parts = $local_ip.Split('.');" ^
    "$prefix = $parts[0] + '.' + $parts[1] + '.' + $parts[2] + '.';" ^
    "$self = [int]$parts[3];" ^
    "Write-Host ('扫描网段：' + $prefix + '2 - ' + $prefix + '255，跳过本机 ' + $local_ip) -ForegroundColor Green;" ^
    "$ips = @();" ^
    "for ($n = 2; $n -le 255; $n++) { if ($n -ne $self) { $ips += ($prefix + $n); }; };" ^
    "$tasks = foreach ($ip in $ips) { (New-Object Net.NetworkInformation.Ping).SendPingAsync($ip, 500); };" ^
    "[System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]$tasks);" ^
    "$online = @();" ^
    "for ($i = 0; $i -lt $ips.Count; $i++) { if ($tasks[$i].Result.Status -eq 'Success') { $online += $ips[$i]; }; };" ^
    "Write-Host ('在线机器（' + $online.Count + ' 台）：') -ForegroundColor Green;" ^
    "$dnsNames = @{};" ^
    "$nameTasks = foreach ($ip in $online) { [Net.Dns]::GetHostEntryAsync($ip); };" ^
    "[void][System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]$nameTasks, 3000);" ^
    "for ($i = 0; $i -lt $online.Count; $i++) {" ^
        "if ($nameTasks[$i].IsCompleted -and -not $nameTasks[$i].IsFaulted) { try { $hostName = $nameTasks[$i].Result.HostName; if ($hostName -and ($hostName -ne $online[$i])) { $dnsNames[$online[$i]] = $hostName; }; } catch { }; };" ^
    "};" ^
    "foreach ($ip in $online) {" ^
        "if ($dnsNames.ContainsKey($ip)) { Write-Host ($ip + '    ' + $dnsNames[$ip]); }" ^
        "else { Write-Host $ip; };" ^
    "};"



echo 扫描完成
echo ==============================
echo.
pause
endlocal & endlocal & exit /b
