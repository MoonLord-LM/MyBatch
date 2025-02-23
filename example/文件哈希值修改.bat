@echo off
echo 通过在文件末尾添加字符0，来修改文件的哈希值
if "%~1"=="" (
    echo 请拖拽文件，到本文件图标上运行
    pause
    exit
)
set /p="0"<nul>>"%~1"
for %%a in ("%~1") do set filename=%%~na
for %%a in ("%~1") do set exname=%%~xa
rename "%~1" "%filename%-0%exname%"
echo 文件的哈希值修改成功，新文件命名为：%filename%-0%exname%
pause
exit