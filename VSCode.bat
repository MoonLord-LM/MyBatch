@echo off

for /f usebackq^ tokens^=1^,2^,*^ delims^=^" %%i ^
in (`reg query "HKCU\Software\Classes\VSCodeSourceFile\shell\open\command" /ve`) ^
do set "vscode_exe=%%j"
echo Visual Studio Code ��ִ�г���·����"%vscode_exe%"

echo Visual Studio Code ����������"%vscode_exe%" "%cd%"
start "" "%vscode_exe%" "%cd%"

::pause
exit