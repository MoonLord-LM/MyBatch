@echo off
echo ��ȡָ���ļ���·���µ��ļ����ļ����б�������Ϊtxt�ļ�
if "%~1"=="" (
    echo ����ק�ļ��У������ļ�ͼ��������
    pause
    exit
)
::for %%a in ("%~1") do echo %%a %%~na %%~xa
for %%a in ("%~1") do set dirname=%%~na%%~xa
tree /f "%~1" >"%dirname%.tree.txt"
dir /o:n /s /b "%~1" >"%dirname%.list.txt"
dir /o:n /s /q /t "%~1" >"%dirname%.dir.txt"
echo �ļ����ļ����б�����ɣ���鿴���ɵ�txt�ļ�
pause
exit