@echo off


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
for /d %%i in (%USERPROFILE%\AppData\Local\SquirrelTemp) do (
    echo rmdir /S /Q ^"%%i^"
    REM rmdir /S /Q "%%i" 1>nul 2>nul
)
echo del /F /S /Q "%USERPROFILE%\AppData\Local\SquirrelTemp\"
REM del /F /S /Q "%USERPROFILE%\AppData\Local\SquirrelTemp\" 1>nul 2>nul

: �û���ʱ�ļ�
for /d %%i in (%USERPROFILE%\AppData\Local\Temp) do (
    echo rmdir /S /Q ^"%%i^"
    REM rmdir /S /Q "%%i" 1>nul 2>nul
)
echo del /F /S /Q "%USERPROFILE%\AppData\Local\Temp\*"
REM del /F /S /Q "%USERPROFILE%\AppData\Local\Temp\*" 1>nul 2>nul


: pause
exit
