@echo off
setlocal enabledelayedexpansion

set "destination=%cd%"

for /r %%i in (*.mp4 *.wmv *.mkv *.avi *.rar) do (
    move "%%i" "!destination!"
)

endlocal
pause
exit
