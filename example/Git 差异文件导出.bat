@echo off

if exist "%~dp0changes.patch" (
    echo �ű�����Ŀ¼�Ѵ��� changes.patch �����ļ�����������
    pause
    echo.
)

:: ��ȡ�϶��� bat �ļ��ϵ������ļ���·��
set "input_dir=%~1"

if "%input_dir%"=="" (
    echo �뽫Ҫ����� Git �ֿ��ļ����϶����˽ű���
    pause
    exit /b
)
if not exist "%input_dir%\" (
    echo ָ�����ļ���·�������ڣ��벻Ҫ�������ļ��϶����˽ű���
    pause
    exit /b
)

cd "%input_dir%"
git add .
git diff HEAD --output="%~dp0changes.patch"
echo ������ "%~dp0changes.patch" �����ļ�
echo.

pause
exit
