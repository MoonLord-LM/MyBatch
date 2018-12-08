@echo off
adb root
adb logcat -c && adb logcat >log.txt
pause
exit