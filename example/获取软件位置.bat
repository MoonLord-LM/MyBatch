@echo off

:: 查找注册表，找到 Visual Studio Code 的 Code.exe 的位置
for /f usebackq^ tokens^=1^,2^,*^ delims^=^" %%i ^
in (`reg query "HKCU\Software\Classes\VSCodeSourceFile\shell\open\command" /ve`) ^
do set "vscode_exe=%%j"
echo Visual Studio Code 可执行程序路径："%vscode_exe%"

pause
exit