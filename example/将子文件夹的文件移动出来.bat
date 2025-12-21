@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 子目录中包含特殊符号，如 ! 时，会报错找不到目录，因此需要使用 endlocal



for /r %%i in (*.mp4 *.mkv *.wmv *.mpg *.avi *.mpeg *.rar) do (
    endlocal
    echo 处理文件: "%%i"
    move "%%i" "%cd%"
    setlocal enabledelayedexpansion
)

pause
exit
