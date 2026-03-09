@echo off

:: MoonLord 2023.07.29  
:: 删除 master 分支的多余的本地文件  

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
