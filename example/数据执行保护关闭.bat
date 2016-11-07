@echo off
bcdedit.exe/set {current} nx alwaysoff
echo 已关闭数据执行保护，需要重新启动计算机才能生效。
pause