@echo off
echo Win7�������汳���޸ģ�ͼƬ��С����С��256KB��
if "%~1"=="" (
echo ����קҪ����Ϊ������ͼƬ�������ļ�ͼ��������
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
if %errorlevel% equ 0 ( echo Win7�������汳���޸ĳɹ���ͼƬ�ļ�Ϊ��%bg% ) else ( echo Win7�������汳���޸�ʧ�ܣ�ͼƬ�ļ�Ϊ��%bg% )
pause
exit

:AdministratorPrivileges - "��ȡ����ԱȨ��"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo �ѻ�ȡ����ԱȨ�� && goto :eof ) else ( echo ��Ҫ��ȡ����ԱȨ�ޣ���ȷ�ϡ��� )
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