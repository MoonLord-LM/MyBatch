@echo off

call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
pushd %~dp0

echo ��ʾ��ʹ�� PowerShell ���Ի�ȡ����ԱȨ�ޣ���ȡʧ��ʱ��������
pause
exit

:AdministratorPrivileges - "��ȡ����ԱȨ��"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo �ѻ�ȡ����ԱȨ�� && goto :eof ) else ( echo ��Ҫ��ȡ����ԱȨ�ޣ���ȷ�ϡ��� )
    powershell start -verb runas "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" 1>nul 2>nul
    if %errorlevel% neq 0 ( echo Ȩ�޻�ȡʧ�ܡ��� && goto :eof )
    exit
goto :eof