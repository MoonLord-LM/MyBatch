@echo off

:: MoonLord 2022.02.22  
:: 根据文件夹后缀（-master、-develop），判断当前是哪个分支  
:: 提交文件夹内的全部修改  
:: 提交到 xx-auto-xxxxxxxx-xxxxxxxx 形式的新分支里  

set "id=%date:~0,4%%date:~5,2%%date:~8,2%-%random%%random%"

echo ---- > "%tmp%\branch.txt"
for /f usebackq %%i in ( `dir /AD /B` ) do (
    echo "processing %%i ..."
    cd "%%i"
    git status | findstr "\clean\>" >nul || (
        echo "%%i" | findstr "\-master\>" >nul && (
            for /f usebackq %%j in ( `git status` ) do (
                echo "%%j" | findstr "* On branch master\>" >nul && (
                    echo "commit: %%j"
                    git stash
                    git checkout -b "master-auto-%id%"
                    git stash pop
                    git add "."
                    git commit -m "auto commit local changes in master branch"
                    git push origin "master-auto-%id%"
                )
            )
        )
        echo "%%i" | findstr "\-develop\>" >nul && (
            for /f usebackq %%j in ( `git status` ) do (
                echo "%%j" | findstr "* On branch develop\>" >nul && (
                    echo "commit: %%j"
                    git stash
                    git checkout -b "develop-auto-%id%"
                    git stash pop
                    git add "."
                    git commit -m "auto commit local changes in develop branch"
                    git push origin "develop-auto-%id%"
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
