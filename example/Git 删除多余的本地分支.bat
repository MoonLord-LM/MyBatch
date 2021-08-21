@echo off

:: MoonLord 2021.08.21  
:: 根据文件夹后缀，判断当前分支，删除多余的本地分支  

echo ---- > "branch.txt"
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
    echo "%%i" | findstr "\-master_nocloud\>" >nul && (
        for /f usebackq %%j in ( `git branch` ) do (
            echo "%%j" | findstr "* master_nocloud\>" >nul || (
                echo "branch to be deleted: %%j"
                git branch -D "%%j"
            )
        )
    )
    echo %%i >> "../branch.txt"
    git branch >> "../branch.txt"
    echo ---- >> "../branch.txt"
    cd ../
)

"explorer.exe" "branch.txt"

pause
exit
