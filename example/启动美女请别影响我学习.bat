@echo off

REM ����Ů���Ӱ����ѧϰ����Ϸ�������������������� LSPGame.exe ���̣���ֹ�ڶ��±���Steam ��������״̬����������쳣��

call :AdministratorPrivileges "%~0" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
pushd %~dp0

REM ���� LSPLauncher.exe
start "" "LSPLauncher.exe"

REM �ȴ� 3 ��
timeout /t 3 /nobreak >nul

REM ���� LSPGame.exe ����
taskkill /im "LSPGame.exe" /f

REM �ȴ� 3 ��
timeout /t 3 /nobreak >nul

exit

:AdministratorPrivileges - "��ȡ����ԱȨ��"
    net file 1>nul 2>nul
    if %errorlevel% equ 0 ( echo �ѻ�ȡ����ԱȨ�� && goto :eof ) else ( echo ��Ҫ��ȡ����ԱȨ�ޣ���ȷ�ϡ��� )
    set vbs="%windir%\Temp\Get_Privileges_%random%.vbs"
    echo Set UAC = CreateObject^("Shell.Application"^)>%vbs%
    echo Args = "">>%vbs%
    echo For Each Argument In WScript.Arguments>>%vbs%
    echo Args = Args ^& Argument ^& " ">>%vbs%
    echo Next>>%vbs%
    echo UAC.ShellExecute "%~1", Args, "", "runas", 1 >>%vbs%
    wscript %vbs% "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
    exit
goto :eof
