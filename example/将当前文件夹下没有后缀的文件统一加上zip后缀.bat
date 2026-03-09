@echo off
chcp 65001 >nul



for %%f in (*) do (
    if not "%%~xf"=="" (
        rem Do nothing
    ) else (
        echo ren "%%f" "%%f.zip"
        ren "%%f" "%%f.zip"
    )
)



pause
exit
