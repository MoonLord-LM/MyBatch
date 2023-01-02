@echo off

:: 腾讯游戏 ACE 服务禁用，优化性能

echo "%date% %time%" >>"AntiCheatExpert Service.txt" 2>>&1
net stop "AntiCheatExpert Service" >>"AntiCheatExpert Service.txt" 2>>&1

exit
