@echo off
SetLocal EnableDelayedExpansion
adb remount
for /r %%c in (*) do (
    @echo on
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
    @echo off
)
adb shell