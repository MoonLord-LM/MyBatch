@echo off

:: MoonLord 2022.01.10  
:: 根据文件夹后缀（-master、-develop、-release、-dev），判断当前是哪个分支  
:: 无文件夹后缀，则默认为 master 分支
:: 同步远程的代码更新（git pull）  
:: 如果本地有正在修改，未提交的代码，则不会更新  

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
