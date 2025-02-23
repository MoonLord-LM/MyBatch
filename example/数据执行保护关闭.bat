@echo off
bcdedit.exe/set {current} nx alwaysoff
echo 请使用鼠标右键菜单的 "以管理员身份运行"
echo 关闭数据执行保护后，需要重新启动计算机才能生效
pause
exit