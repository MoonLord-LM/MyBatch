@echo off
setlocal enabledelayedexpansion

::
::  ���¡�help���ļ����е����е����������Ϣ
::

call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
pushd %~dp0

del /F /S /Q "help\*"
if not exist "tmp\" ( mkdir "tmp\" )
echo :: ��ʱ�ű�>"tmp\help.tmp.bat"

for %%i in (

at cd fc if md rd
arp cls cmd del dir for msg net rem ren set sfc ver vol
call chcp clip comp copy date dism echo exit find goto mode more move path ping popd setx sort time tree type wmic
assoc cacls color erase fltmc ftype label mkdir netsh pause print pushd quser rmdir shift start subst title w32tm where xcopy
attrib change chkdsk choice cipher defrag doskey expand format fsutil getmac icacls lodctr logman logoff mklink nltest prompt rename setspn tskill tzutil verify whoami
bcdboot bcdedit certreq chkntfs compact convert findstr makecab nbtstat netstat qappsrv qwinsta recover replace takeown timeout tracert waitfor wbadmin wecutil
certutil endlocal diskcomp diskcopy forfiles gpresult gpupdate hostname ipconfig mountvol nslookup pathping powercfg qprocess schtasks setlocal shutdown tasklist taskkill tsdiscon typeperf vssadmin wevtutil
openfiles
powershell systeminfo
eventcreate

) do (

echo echo %%i /? ^^^>"help\%%i.txt" 2^^^>^^^&1 1>>"tmp\help.tmp.bat" && ^
echo %%i /? ^>"help\%%i.txt" 2^>^&1 1>>"tmp\help.tmp.bat"

)
call "tmp\help.tmp.bat"

change logon /? >>"help\change.txt" 2>>&1
change port /? >>"help\change.txt" 2>>&1
change user /? >>"help\change.txt" 2>>&1

cmd /c winrm /? >>"help\winrm.txt" 2>>&1

echo Set wshell = CreateObject("Wscript.shell") >"tmp\help.tmp.vbs"
echo WScript.Sleep 1000 >>"tmp\help.tmp.vbs"
echo wshell.Sendkeys "Y{enter}" >>"tmp\help.tmp.vbs"
cmd /c wscript "%cd%\tmp\help.tmp.vbs"
sc >>"help\sc.txt" 2>>&1
echo.

REM del /q "tmp\help.tmp.bat"
REM del /q "tmp\help.tmp.vbs"
pause
exit

:AdministratorPrivileges - "��ȡ����ԱȨ��"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo �ѻ�ȡ����ԱȨ�� && goto :eof ) else ( echo ��Ҫ��ȡ����ԱȨ�ޣ���ȷ�ϡ��� )
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