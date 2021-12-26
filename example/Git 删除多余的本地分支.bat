@echo off

:: MoonLord 2021.10.29  
:: 根据文件夹后缀（-master、-develop、-ICSL），判断当前是哪个分支  
:: 删除多余的本地分支  
:: 仅保留一个主要的分支  

echo ---- > "%tmp%\branch.txt"
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
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
    echo "%%i" | findstr "\-ICSL\>" >nul && (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* ICSL\>" >nul || (
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
