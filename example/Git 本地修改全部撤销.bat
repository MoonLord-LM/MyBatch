@echo off

:: MoonLord 2021.10.29  
:: �����ļ��к�׺��-master��-develop��-ICSL�����жϵ�ǰ���ĸ���֧  
:: ɾ������ı��ط�֧  
:: ������һ����Ҫ�ķ�֧  

echo ---- > "%tmp%\branch.txt"
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    echo "branch to be reset: %%i"
    git reset HEAD
    git checkout .
    cd ../
)

pause
exit
