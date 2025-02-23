@echo off

:: 关闭 Windows 外壳程序 Explorer
taskkill /f /im explorer.exe

:: 清理文件图标缓存
attrib -h -s -r "%userprofile%\AppData\Local\IconCache.db"
del /f "%userprofile%\AppData\Local\IconCache.db"

attrib /s /d -h -s -r "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\*.db"
del /f "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\*.db"

:: 清理系统托盘图标缓存
echo y | reg delete "HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" /v IconStreams
echo y | reg delete "HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" /v PastIconsStream

:: 重启 Windows 外壳程序 Explorer
start explorer

pause
exit
