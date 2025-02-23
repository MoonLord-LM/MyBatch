@echo off

:: MoonLord 2022.01.10
:: ͬ��Ŀ¼�´�� Git �����ļ��У���������Ϊ������+��֧�������ܰ����ո�
:: �����ļ��к�׺��-master��-develop��-release��-dev�����жϵ�ǰ���ĸ���֧
:: ���ļ��к�׺����Ĭ��Ϊ master ��֧
:: ͬ��Զ�̵Ĵ�����£�git pull��
:: ��������������޸ģ�δ�ύ�Ĵ��룬�򲻻����

:: dir /AD /B >dir.txt

:start
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    echo "%%i" | findstr "\-\>" >nul || (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout "master" --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-master\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout "master" --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-develop\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout "develop" --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-release\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout "release" --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-dev\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout "dev" --
        git.exe pull -v --progress --no-rebase "origin"
    )
    cd ../
)
cls
goto :start

pause
exit
