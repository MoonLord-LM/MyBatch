@echo off
setlocal enabledelayedexpansion

echo ����ɨ������� 192.168.1.1 - 192.168.1.10 ���豸...
echo ==============================
echo.

for /l %%i in (1, 1, 10) do (
    set ip=192.168.1.%%i

    echo ���ڼ�� !ip!...
    ping -n 1 -w 300 !ip! >nul

    if !errorlevel! equ 0 (
        ping -n 1 -a !ip! | findstr /i "!ip!"
        echo ------------------------------
    )
)

echo.
echo ɨ�����
echo ==============================
pause
exit
