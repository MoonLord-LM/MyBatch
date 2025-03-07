@echo off
setlocal enabledelayedexpansion

echo 正在扫描局域网 192.168.1.1 - 192.168.1.10 的设备...
echo ==============================
echo.

for /l %%i in (1, 1, 10) do (
    set ip=192.168.1.%%i

    echo 正在检查 !ip!...
    ping -n 1 -w 300 !ip! >nul

    if !errorlevel! equ 0 (
        ping -n 1 -a !ip! | findstr /i "!ip!"
        echo ------------------------------
    )
)

echo.
echo 扫描完成
echo ==============================
pause
exit
