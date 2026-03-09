@echo off
chcp 65001 >nul
adb root
adb logcat -c && adb logcat >log.txt
pause
exit