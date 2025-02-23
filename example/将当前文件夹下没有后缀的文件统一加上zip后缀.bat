@echo off

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
