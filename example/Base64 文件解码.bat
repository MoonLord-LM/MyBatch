@echo off
setlocal

:: ��ȡ�϶��� bat �ļ��ϵ������ļ�·��
set "input_file=%~1"

:: ����Ƿ��ṩ�������ļ�
if "%input_file%"=="" (
    echo �뽫Ҫ������ļ��϶����˽ű���
    pause
    exit /b
)

:: ��������ļ�·����Ĭ��Ϊԭ�ļ������� .decode ��׺
set "output_file=%input_file%.decode"

:: ʹ�� certutil ���� Base64 ����
certutil -decode "%input_file%" "%output_file%" >nul
