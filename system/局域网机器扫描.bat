@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
if /i "!cd!"=="!SystemRoot!\System32" ( cd /d "!script_dir!" )
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '根据本机局域网 IP 并发扫描同网段 0-255 的地址，列出其它机器的 IP 和主机名' -ForegroundColor Green"
echo.



set "local_ip="
for /f "delims=" %%a in ('powershell -NoProfile -Command "try { (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress } catch { }"') do set "local_ip=%%a"

if "!local_ip!"=="" (
    echo 获取本机局域网 IP 失败 & REM
    echo.
    pause
    exit /b 1
)



echo 本机局域网 IP：!local_ip!
echo.

echo 开始扫描...
echo.

powershell -NoProfile -Command ^
    "[System.Console]::OutputEncoding=[System.Text.Encoding]::UTF8;" ^
    "$localIp = $env:local_ip;" ^
    "$parts = $localIp.Split('.');" ^
    "$prefix = $parts[0] + '.' + $parts[1] + '.' + $parts[2] + '.';" ^
    "$self = [int]$parts[3];" ^
    "Write-Host ('扫描网段：' + $prefix + '0 - ' + $prefix + '255');" ^
    "$ips = @();" ^
    "for ($n = 0; $n -le 255; $n++) {" ^
    "    if ($n -ne $self) {" ^
    "        $ips += ($prefix + $n);" ^
    "    };" ^
    "};" ^
    "$statuses = foreach ($ip in $ips) {" ^
    "    $ping = [System.Net.NetworkInformation.Ping]::new();" ^
    "    try {" ^
    "        $reply = $ping.SendPingAsync($ip, 500).GetAwaiter().GetResult();" ^
    "        $reply.Status;" ^
    "    }" ^
    "    finally {" ^
    "        $ping.Dispose();" ^
    "    }" ^
    "};" ^
    "$online = @();" ^
    "for ($i = 0; $i -lt $ips.Count; $i++) {" ^
    "    if ($statuses[$i] -eq 'Success') {" ^
    "        $online += $ips[$i];" ^
    "    };" ^
    "};" ^
    "Write-Host ('扫描结果（' + $online.Count + ' 个）：');" ^
    "$dnsNames = @{};" ^
    "$nameTasks = foreach ($ip in $online) {" ^
    "    [System.Net.Dns]::GetHostEntryAsync($ip);" ^
    "};" ^
    "[System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]$nameTasks, 3000) | Out-Null;" ^
    "for ($i = 0; $i -lt $online.Count; $i++) {" ^
    "    if ($nameTasks[$i].IsCompleted -and -not $nameTasks[$i].IsFaulted) {" ^
    "        try {" ^
    "            $hostName = $nameTasks[$i].Result.HostName;" ^
    "            if ($hostName -and ($hostName -ne $online[$i])) {" ^
    "                $dnsNames[$online[$i]] = $hostName;" ^
    "            };" ^
    "        } catch { };" ^
    "    };" ^
    "};" ^
    "foreach ($ip in $online) {" ^
        "if ($dnsNames.ContainsKey($ip)) {" ^
    "        Write-Host ($ip + '    ' + $dnsNames[$ip]) -ForegroundColor Green;" ^
    "    }" ^
        "else {" ^
    "        Write-Host $ip -ForegroundColor Green;" ^
    "    };" ^
    "};"

echo.
echo 扫描完成



echo.
pause
exit /b
