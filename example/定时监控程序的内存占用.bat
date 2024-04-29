@echo off
setlocal EnableDelayedExpansion

set PROCESS_NAME=360ChromeX.exe
set LOG_FILE=memory_usage.log
set INTERVAL=60


echo. > "%LOG_FILE%"

:LOOP
for /f "tokens=*" %%a in ('tasklist /fi "imagename eq %PROCESS_NAME%" /fo csv /nh') do (
    for /f "tokens=* delims=," %%b in ("%%a") do (
        set "MEMORY_USAGE=%%b"
        echo !DATE! !TIME! - Memory Usage: !MEMORY_USAGE! >> "%LOG_FILE%"
    )
)

timeout /t %INTERVAL% /nobreak >nul

goto LOOP
