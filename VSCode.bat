@echo off

:: ���齫 Visual Studio Code ���뵽 PATH ��������
Code "%cd%" 1>nul 2>nul
:: Code �������ִ�гɹ������´���Ͳ�����ִ��

for /f usebackq^ tokens^=1^,2^,*^ delims^=^" %%i ^
in (`reg query "HKCU\Software\Classes\VSCodeSourceFile\shell\open\command" /ve`) ^
do set "vscode_exe=%%j"
if "%vscode_exe%" neq "" goto :start

for /f usebackq^ tokens^=1^,2^,*^ delims^=^" %%i ^
in (`reg query "HKCR\Applications\Code.exe\shell\open\command" /ve`) ^
do set "vscode_exe=%%j"
if "%vscode_exe%" neq "" goto :start

pause & exit

:start - ���� Visual Studio Code
echo Visual Studio Code ��ִ�г���·����"%vscode_exe%"
echo Visual Studio Code ����������"%vscode_exe%" "%cd%"
start "" "%vscode_exe%" "%cd%"

pause
exit