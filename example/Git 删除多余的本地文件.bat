@echo off

:: MoonLord 2023.07.29  
:: ɾ�� master ��֧�Ķ���ı����ļ�  

echo ---- > "%tmp%\branch.txt"
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    echo "%%i" | findstr "\-master\>" >nul && (
        git clean -f
    )
    cd ../
)

pause
exit
