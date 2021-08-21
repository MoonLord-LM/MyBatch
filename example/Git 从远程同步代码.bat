@echo off

:: MoonLord 2021.08.21  
:: 根据文件夹后缀，判断当前分支，从远程更新 Git 仓库代码  
:: 本地有正在修改，未提交的代码，则不会更新  

dir /AD /B >dir.txt

:start
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    echo "%%i" | findstr "\-master\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout master --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-develop\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout develop --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-ICSL\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout ICSL --
        git.exe pull -v --progress --no-rebase "origin"
    )
    echo "%%i" | findstr "\-master_nocloud\>" >nul && (
        git.exe pull -v --progress --no-rebase "origin"
        git.exe checkout master_nocloud --
        git.exe pull -v --progress --no-rebase "origin"
    )
    cd ../
)
cls
goto :start

pause
exit
