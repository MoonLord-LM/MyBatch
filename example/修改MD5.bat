REM ��ʾ��ͨ�����ļ�ĩβ����ַ�0���޸��ļ�MD5ֵ
@echo off
if "%~1"=="" (
@echo on
echo ����������Ҫ�����ļ���������ͼ��������
pause
exit
)
set /p="MoonLord"<nul>>"%~1"
for %%a in ("%~1") do set exname=%%~xa
for %%a in ("%~1") do set filename=%%~na
rename "%~1" "%filename%-MoonLord%exname%"
echo �ļ�MD5ֵ�޸ĳɹ������ļ�����Ϊ%filename%-MoonLord%exname%
@echo on
pause
exit