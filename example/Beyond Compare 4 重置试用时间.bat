@echo off

:: Beyond Compare 4 重置试用时间
reg delete "HKEY_CURRENT_USER\Software\Scooter Software\Beyond Compare 4" /v CacheID /f

pause
exit
