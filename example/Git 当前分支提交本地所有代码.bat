@echo off

:: MoonLord 2022.02.22  
:: �����ļ��к�׺��-master��-develop�����жϵ�ǰ���ĸ���֧  
:: �ύ�ļ����ڵ�ȫ���޸�  

echo ---- > "%tmp%\branch.txt"
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    git status | findstr "\clean\>" >nul || (
        echo "%%i" | findstr "\-master\>" >nul && (
            for /f usebackq %%j in ( `git status` ) do (
                echo "%%j" | findstr "* On branch master\>" >nul && (
                    echo "commit: %%j"
                    git add "."
                    git commit -m "auto commit local changes in master branch"
                    git push origin "master"
                )
            )
        )
        echo "%%i" | findstr "\-develop\>" >nul && (
            for /f usebackq %%j in ( `git status` ) do (
                echo "%%j" | findstr "* On branch develop\>" >nul && (
                    echo "commit: %%j"
                    git add "."
                    git commit -m "auto commit local changes in develop branch"
                    git push origin "develop"
                )
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
