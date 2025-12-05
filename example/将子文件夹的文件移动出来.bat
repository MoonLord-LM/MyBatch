@echo off
setlocal enabledelayedexpansion

set "destination=%cd%"

for /r %%i in (*.mp4 *.mkv *.wmv *.mpg *.avi *.mpeg *.rar) do (
    move "%%i" "!destination!"
)

endlocal
pause
exit
