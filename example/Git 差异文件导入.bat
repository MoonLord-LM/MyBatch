@echo off

if not exist "%~dp0changes.patch" (
    echo �ű�����Ŀ¼������ changes.patch �����ļ�
    pause
    exit /b
)

:: ��ȡ�϶��� bat �ļ��ϵ������ļ���·��
set "input_dir=%~1"

if "%input_dir%"=="" (
    echo �뽫Ҫ����� Git �ֿ��ļ����϶����˽ű���
    pause
    exit /b
)
if not exist "%input_file%\" (
    echo �벻Ҫ�������ļ��϶����˽ű���
    pause
    exit /b
)

cd "%input_dir%"
git apply "%~dp0changes.patch"
echo �ѵ��� "%~dp0changes.patch" �����ļ�
echo.

pause
exit
