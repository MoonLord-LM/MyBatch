@echo off
echo Win7锁屏界面背景修改（图片大小必须小于256KB）
if "%~1"=="" (
echo 请拖拽要设置为背景的图片，到本文件图标上运行
pause
exit
)
call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
set tmp=C:\Windows\Temp\LogonUI_Background.reg
echo Windows Registry Editor Version 5.00>%tmp%
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background]>>%tmp%
echo "OEMBackground"=dword:00000001>>%tmp%
reg import %tmp%
set bg="%~1 %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9"
copy %bg% "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg" /y
if %errorlevel% equ 0 ( echo Win7锁屏界面背景修改成功，图片文件为：%bg% ) else ( echo Win7锁屏界面背景修改失败，图片文件为：%bg% )
pause
exit

:AdministratorPrivileges - "获取管理员权限"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo 已获取管理员权限 && goto :eof ) else ( echo 需要获取管理员权限，请确认…… )
    set vbs=C:\Windows\Temp\Get_Privileges.vbs
    echo Set UAC = CreateObject^("Shell.Application"^)>%vbs%
    echo Args = "">>%vbs%
    echo For Each Argument In WScript.Arguments>>%vbs%
    echo Args = Args ^& Argument ^& " ">>%vbs%
    echo Next>>%vbs%
    echo UAC.ShellExecute "%~1", Args, "", "runas", 1 >>%vbs%
    "%SystemRoot%\System32\WScript.exe" %vbs% "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
    exit
goto :eof