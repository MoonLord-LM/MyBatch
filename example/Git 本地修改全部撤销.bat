@echo off

:: MoonLord 2021.10.29  
:: 根据文件夹后缀（-master、-develop、-ICSL），判断当前是哪个分支  
:: 删除多余的本地分支  
:: 仅保留一个主要的分支  

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
