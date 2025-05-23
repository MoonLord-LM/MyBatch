@echo off
echo 获取指定文件夹路径下的文件和文件夹列表，并保存为txt文件
if "%~1"=="" (
    echo 请拖拽文件夹，到本文件图标上运行
    pause
    exit
)
::for %%a in ("%~1") do echo %%a %%~na %%~xa
for %%a in ("%~1") do set dirname=%%~na%%~xa
tree /f "%~1" >"%dirname%.tree.txt"
dir /o:n /s /b "%~1" >"%dirname%.list.txt"
dir /o:n /s /q /t "%~1" >"%dirname%.dir.txt"
echo 文件和文件夹列表保存完成，请查看生成的txt文件
pause
exit