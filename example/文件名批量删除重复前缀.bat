@echo off
setlocal enabledelayedexpansion

REM 找到第一个文件名作为基准
for %%f in (*.jpg) do (
    set "prefix=%%~nf"
    goto :found
)
:found

REM 不断缩短前缀，直到所有文件名都以它开头
:shrink
set "ok=1"
for %%f in (*.jpg) do (
    set "name=%%~nf"
    echo !name! | findstr /b "!prefix!" >nul || set "ok=0"
)
if !ok! equ 0 (
    set "prefix=!prefix:~0,-1!"
    goto :shrink
)

echo 公共前缀是: "!prefix!"

REM 执行重命名，去掉公共前缀
for %%f in (*.jpg) do (
    set "name=%%~nf"
    set "rest=!name:%prefix%=!"
    ren "%%f" "!rest!%%~xf"
)

echo 重命名完成！
pause
exit
