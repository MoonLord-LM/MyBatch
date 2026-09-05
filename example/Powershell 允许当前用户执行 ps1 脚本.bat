@echo off
chcp 65001 >nul

REM Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

powershell -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
if %errorlevel% equ 0 (
    echo 策略设置成功，已允许当前用户执行 ps1 脚本
) else (
    echo 策略设置设置失败，错误代码：%errorlevel%
)

pause
