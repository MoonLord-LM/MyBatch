@echo off

REM 《美女请别影响我学习》游戏启动程序，启动三秒后结束 LSPGame.exe 进程，防止第二章报错“Steam 处于离线状态或网络存在异常”

call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
pushd %~dp0

REM 启动 LSPLauncher.exe
start "" "LSPLauncher.exe"

REM 等待 3 秒
timeout /t 3 /nobreak >nul

REM 结束 LSPGame.exe 进程
taskkill /im "LSPGame.exe" /f

REM 等待 3 秒
timeout /t 3 /nobreak >nul

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
