@echo off
chcp 65001 >nul

echo.
echo 正在打开打开 "shell:AppsFolder" 虚拟应用列表
echo 可以在这个列表中，为 UWP 应用创建桌面快捷方式
echo.

explorer.exe "shell:AppsFolder"

pause
exit
