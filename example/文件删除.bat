@echo off
setlocal enabledelayedexpansion
if "%~1"=="" (
    echo ����קҪɾ�����ļ��������ļ�ͼ��������
    pause
    exit
)

:: UNC ·����ʽ��\\servername\sharename
:: ʹ�� UNC ·��������·���еı������豸���Ƶȣ���˿���ɾ�������ļ���Ŀ¼

set "target_file=%~1"
del /F /S /Q "\\?\%target_file%"

pause
exit