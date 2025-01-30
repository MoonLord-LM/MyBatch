@echo off
setlocal enabledelayedexpansion



:: 龙之谷 DragonNest
set "regPath=HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SHENGQUGAMES\DN"
set "keyName=Loader"
for /f "tokens=2,*" %%A in ('reg query "%regPath%" /v "%keyName%" ^| findstr /i "%keyName%"') do (
    set "fullValue=%%B"
)
if not "%fullValue%"=="" (
    for %%F in ("%fullValue%") do set "dirPath=%%~dpF"
    echo DragonNest Game Path: !dirPath!
    del /q "!dirPath!\*.dmp"
    del /q "!dirPath!\Log\*.log"
    del /q "!dirPath!\Log\*.txt"
    del /q "!dirPath!\TempRes\*.tmp"
) else (
    echo Could not find DragonNest Game Path
)

:: 原神 Genshin Impact
set "regPath=HKEY_CURRENT_USER\Software\miHoYo\HYP\1_1\hk4e_cn"
set "keyName=GameInstallPath"
for /f "tokens=2,*" %%A in ('reg query "%regPath%" /v "%keyName%" ^| findstr /i "%keyName%"') do (
    set "fullValue=%%B"
)
if not "%fullValue%"=="" (
    for %%F in ("%fullValue%") do set "dirPath=%%~dpF"
    echo Genshin Impact Game Path: !dirPath!
    del /q "!dirPath!\Genshin Impact Game\*.dmp"
    del /q "!dirPath!\logs\*.log"
) else (
    echo Could not find Genshin Impact Game Path
)



endlocal
pause
exit
