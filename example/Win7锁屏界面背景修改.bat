@echo off
echo Win7�������汳���޸ģ�ͼƬ��С����С��256KB��
if "%~1"=="" (
    echo ����קҪ����Ϊ������ͼƬ�������ļ�ͼ��������
    pause
    exit
)
call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
set tmp="C:\Windows\Temp\LogonUI_Background_%random%.reg"
echo Windows Registry Editor Version 5.00>%tmp%
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background]>>%tmp%
echo "OEMBackground"=dword:00000001>>%tmp%
reg import %tmp%
set bg="%~1"
if "%~2" neq "" ( set bg="%~1 %~2" )
if "%~3" neq "" ( set bg="%~1 %~2 %~3" )
if "%~4" neq "" ( set bg="%~1 %~2 %~3 %~4" )
if "%~5" neq "" ( set bg="%~1 %~2 %~3 %~4 %~5" )
if "%~6" neq "" ( set bg="%~1 %~2 %~3 %~4 %~5 %~6" )
if "%~7" neq "" ( set bg="%~1 %~2 %~3 %~4 %~5 %~6 %~7" )
if "%~8" neq "" ( set bg="%~1 %~2 %~3 %~4 %~5 %~6 %~7 %~8" )
if "%~9" neq "" ( set bg="%~1 %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9" )
if not exist "bg" (
    echo Win7�������汳���޸�ʧ�ܣ�ͼƬ�����ڣ�%bg%
    pause
    exit
)
copy %bg% "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg" /y
if %errorlevel% equ 0 ( echo Win7�������汳���޸ĳɹ���ͼƬ�ļ�Ϊ��%bg% ) else ( echo Win7�������汳���޸�ʧ�ܣ�ͼƬ�ļ�Ϊ��%bg% )
pause
exit

:AdministratorPrivileges - "��ȡ����ԱȨ��"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo �ѻ�ȡ����ԱȨ�� && goto :eof ) else ( echo ��Ҫ��ȡ����ԱȨ�ޣ���ȷ�ϡ��� )
    set vbs="C:\Windows\Temp\Get_Privileges_%random%.vbs"
    echo Set UAC = CreateObject^("Shell.Application"^)>%vbs%
    echo Args = "">>%vbs%
    echo For Each Argument In WScript.Arguments>>%vbs%
    echo Args = Args ^& Argument ^& " ">>%vbs%
    echo Next>>%vbs%
    echo UAC.ShellExecute "%~1", Args, "", "runas", 1 >>%vbs%
    "%SystemRoot%\System32\WScript.exe" %vbs% "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
    exit
goto :eof