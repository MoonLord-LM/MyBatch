@echo off
echo ͨ�����ļ�ĩβ����ַ�0�����޸��ļ��Ĺ�ϣֵ
if "%~1"=="" (
    echo ����ק�ļ��������ļ�ͼ��������
    pause
    exit
)
set /p="0"<nul>>"%~1"
for %%a in ("%~1") do set filename=%%~na
for %%a in ("%~1") do set exname=%%~xa
rename "%~1" "%filename%-0%exname%"
echo �ļ��Ĺ�ϣֵ�޸ĳɹ������ļ�����Ϊ��%filename%-0%exname%
pause
exit