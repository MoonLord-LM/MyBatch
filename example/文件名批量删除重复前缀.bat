@echo off
setlocal enabledelayedexpansion

REM �ҵ���һ���ļ�����Ϊ��׼
for %%f in (*.jpg) do (
    set "prefix=%%~nf"
    goto :found
)
:found

REM ��������ǰ׺��ֱ�������ļ�����������ͷ
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

echo ����ǰ׺��: "!prefix!"

REM ִ����������ȥ������ǰ׺
for %%f in (*.jpg) do (
    set "name=%%~nf"
    set "rest=!name:%prefix%=!"
    ren "%%f" "!rest!%%~xf"
)

echo ��������ɣ�
pause
exit
