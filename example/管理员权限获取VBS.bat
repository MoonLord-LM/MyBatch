@echo off

call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
pushd %~dp0

echo 提示：使用 VBScript 尝试获取管理员权限，获取失败时直接退出
pause
exit

:AdministratorPrivileges - "获取管理员权限"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo 已获取管理员权限 && goto :eof ) else ( echo 需要获取管理员权限，请确认…… )
    set vbs="%windir%\Temp\Get_Privileges_%random%.vbs"
    echo Set UAC = CreateObject^("Shell.Application"^)>%vbs%
    echo Args = "">>%vbs%
    echo For Each Argument In WScript.Arguments>>%vbs%
    echo Args = Args ^& Argument ^& " ">>%vbs%
    echo Next>>%vbs%
    echo UAC.ShellExecute "%~1", Args, "", "runas", 1 >>%vbs%
    wscript %vbs% "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
    exit
goto :eof