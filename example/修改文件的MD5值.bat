REM ��ʾ��ͨ�����ļ�ĩβ����ַ�0���޸��ļ�MD5ֵ
@echo off
if "%~1"=="" (
@echo on
echo ����������Ҫ�����ļ���������ͼ��������
pause
exit
)
set /p="0"<nul>>"%~1"
for %%a in ("%~1") do set exname=%%~xa
for %%a in ("%~1") do set filename=%%~na
rename "%~1" "%filename%-0%exname%"
echo �ļ�MD5ֵ�޸ĳɹ������ļ�����Ϊ%filename%-0%exname%
@echo on
pause
exit