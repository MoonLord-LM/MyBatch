@echo off

if "%JAVA_HOME%"=="" (
    echo �������� JDK ��װ·���Ļ���������JAVA_HOME
    pause
    exit
)

echo ��ǰ JDK ��װ·����%JAVA_HOME%
echo ��ǰ .jar �ļ��Ĵ򿪷�ʽ��
for /f "usebackq tokens=1,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar"`) ^
do (
    reg query "%%i"
)

echo �޸� javaw.exe �� -jar ���в�����
reg add "HKCR\Applications\javaw.exe\shell\open\command" /ve /d "\"%JAVA_HOME%\bin\javaw.exe\" -jar \"%%1\"" /f
reg query "HKCR\Applications\javaw.exe\shell\open\command"

pause
exit