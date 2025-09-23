@echo off
setlocal enabledelayedexpansion

set "destination=%cd%"

for /r %%i in (*.mp4 *.wmv *.mkv *.avi *.rar *.ts) do (
    move "%%i" "!destination!"
)

endlocal
pause
exit
