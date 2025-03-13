@echo off

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v RecycleBinDrives /t REG_DWORD /d 0xffffffff /f
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

pause
exit
