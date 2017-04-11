REM 提示：通过在文件末尾添加字符0来修改文件MD5值
@echo off
if "%~1"=="" (
@echo on
echo 本批处理需要拖入文件到批处理图标上运行
pause
exit
)
set /p="0"<nul>>"%~1"
for %%a in ("%~1") do set exname=%%~xa
for %%a in ("%~1") do set filename=%%~na
rename "%~1" "%filename%-0%exname%"
echo 文件MD5值修改成功，新文件命名为%filename%-0%exname%
@echo on
pause
exit