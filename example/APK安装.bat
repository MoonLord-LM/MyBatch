@echo off
setlocal enabledelayedexpansion
adb remount
for /r "%cd%" %%c in (*) do (
    REM echo %%c
    set line=%%c
    REM echo !line!
    REM //截取末尾4位
    set type=!line:~-4%!
    REM echo !type!
    if "!type!" == ".apk" (
        echo "正在安装!line!……"
        adb install -r !line!
    )
)
adb shell
pause
exit