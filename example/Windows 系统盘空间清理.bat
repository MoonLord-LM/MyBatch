@echo off


:: Windows ϵͳ���߱����ļ�
powercfg -h off


:: Intel Extreme Tuning Utility ��־�ļ�
echo del /F /S /Q "C:\ProgramData\Intel\Intel Extreme Tuning Utility\Logs\*"
del /F /S /Q "C:\ProgramData\Intel\Intel Extreme Tuning Utility\Logs\*" 1>nul 2>nul


: JxBrowser ������ؼ� dmp �ļ�
echo del /F /S /Q "%USERPROFILE%\AppData\Local\JxBrowser\*.dmp"
del /F /S /Q "%USERPROFILE%\AppData\Local\JxBrowser\*.dmp" 1>nul 2>nul


: Adobe ý�建���ļ�
echo del /F /S /Q "%USERPROFILE%\AppData\Roaming\Adobe\Common\Media Cache Files\*"
del /F /S /Q "%USERPROFILE%\AppData\Roaming\Adobe\Common\Media Cache Files\*" 1>nul 2>nul


: Squirrel ������ʱ�ļ�
for /d %%i in (%USERPROFILE%\AppData\Local\SquirrelTemp\*) do (
    echo rmdir /S /Q ^"%%i^"
    rmdir /S /Q "%%i" 1>nul 2>nul
)
echo del /F /S /Q "%USERPROFILE%\AppData\Local\SquirrelTemp\*"
del /F /S /Q "%USERPROFILE%\AppData\Local\SquirrelTemp\*" 1>nul 2>nul


: JetBrains IntelliJ Idea ������ʱ�ļ�
for /d %%i in (%USERPROFILE%\AppData\Local\JetBrains\*) do (
    echo rmdir /S /Q ^"%%i\tmp\patch-update\^"
    rmdir /S /Q "%%i\tmp\patch-update\" 1>nul 2>nul
    echo del /F /S /Q ^"%%i\tmp\*^"
    del /F /S /Q "%%i\tmp\*" 1>nul 2>nul
)


:: Unity Web Player ������������
for /d %%i in (%USERPROFILE%\AppData\LocalLow\Unity\WebPlayer\Cache\*) do (
    echo rmdir /S /Q ^"%%i^"
    rmdir /S /Q "%%i" 1>nul 2>nul
)
echo del /F /S /Q "%USERPROFILE%\AppData\LocalLow\Unity\WebPlayer\Cache\*"
del /F /S /Q "%USERPROFILE%\AppData\LocalLow\Unity\WebPlayer\Cache\*" 1>nul 2>nul


: pause
exit
