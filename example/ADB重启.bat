@echo off
adb nodaemon server
netstat -ano | findstr "5037"
netstat -ano | findstr "5037" >"%windir%\Temp\adb_restart.log"
for /f "delims=" %%i in (%windir%\Temp\adb_restart.log) do (
    REM echo %%i
    set line=%%i
    setlocal enabledelayedexpansion
    REM echo !line!
    REM //��ȡĩβ5λ
    set pid=!line:~-5%!
    REM //�滻�ո�
    set pid=!pid: =!
    REM echo !pid!
    REM //���̺�0Ϊϵͳ����
    if not "!pid!" == "0" (
        taskkill /f /pid !pid!
    )
)
adb shell
del /F /S /Q "%windir%\Temp\adb_restart.log"
pause
exit