@echo off

:: MoonLord 2022.01.10
:: ͬ��Ŀ¼�´�� Git �����ļ��У���������Ϊ������+��֧�������ܰ����ո�
:: �����ļ��к�׺��-master��-develop��-release��-dev�����жϵ�ǰ���ĸ���֧
:: ���ļ��к�׺����Ĭ��Ϊ master ��֧
:: ɾ������ı��ط�֧
:: ������һ����Ҫ�ķ�֧

:: dir /AD /B >dir.txt

echo ---- > "%tmp%\branch.txt"
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    echo "%%i" | findstr "\-\>" >nul || (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* master\>" >nul || (
                echo "branch to be deleted: %%j"
                git branch -D "%%j"
            )
        )
    )
    echo "%%i" | findstr "\-master\>" >nul && (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* master\>" >nul || (
                echo "branch to be deleted: %%j"
                git branch -D "%%j"
            )
        )
    )
    echo "%%i" | findstr "\-develop\>" >nul && (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* develop\>" >nul || (
                echo "branch to be deleted: %%j"
                git branch -D "%%j"
            )
        )
    )
    echo "%%i" | findstr "\-release\>" >nul && (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* release\>" >nul || (
                echo "branch to be deleted: %%j"
                git branch -D "%%j"
            )
        )
    )
    echo "%%i" | findstr "\-dev\>" >nul && (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* dev\>" >nul || (
                echo "branch to be deleted: %%j"
                git branch -D "%%j"
            )
        )
    )
    echo %%i >> "%tmp%\branch.txt"
    git branch >> "%tmp%\branch.txt"
    echo ---- >> "%tmp%\branch.txt"
    cd ../
)

echo "explorer.exe" "%tmp%\branch.txt"
"explorer.exe" "%tmp%\branch.txt"

pause
exit
