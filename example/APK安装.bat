@echo off
setlocal enabledelayedexpansion
adb remount
for /r "%cd%" %%c in (*) do (
    REM echo %%c
    set line=%%c
    REM echo !line!
    REM //��ȡĩβ4λ
    set type=!line:~-4%!
    REM echo !type!
    if "!type!" == ".apk" (
        echo "���ڰ�װ!line!����"
        adb install -r !line!
    )
)
adb shell
pause
exit