@echo off

if "%JAVA_HOME%"=="" (
    echo 请先配置 JDK 安装路径的环境变量：JAVA_HOME
    pause
    exit
)

echo 当前 JDK 安装路径：%JAVA_HOME%
echo 当前 .jar 文件的打开方式：
for /f "usebackq tokens=1,*" %%i ^
in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar"`) ^
do (
    reg query "%%i"
)

echo 修复 javaw.exe 的 -jar 运行参数：
reg add "HKCR\Applications\javaw.exe\shell\open\command" /ve /d "\"%JAVA_HOME%\bin\javaw.exe\" -jar \"%%1\"" /f
reg query "HKCR\Applications\javaw.exe\shell\open\command"

pause
exit