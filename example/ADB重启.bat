@echo off
adb nodaemon server
netstat -ano | findstr "5037"
netstat -ano | findstr "5037" > C:\Windows\Temp\adb_restart.log
for /f "delims=" %%i in (C:\Windows\Temp\adb_restart.log) do (
    @echo on
    REM echo %%i
    set line=%%i
    SetLocal EnableDelayedExpansion
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
    @echo off
)
adb shell