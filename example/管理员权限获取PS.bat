@echo off

call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
pushd %~dp0

echo 提示：使用 PowerShell 尝试获取管理员权限，获取失败时可做处理
pause
exit

:AdministratorPrivileges - "获取管理员权限"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo 已获取管理员权限 && goto :eof ) else ( echo 需要获取管理员权限，请确认…… )
    powershell start -verb runas "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" 1>nul 2>nul
    if %errorlevel% neq 0 ( echo 权限获取失败…… && goto :eof )
    exit
goto :eof