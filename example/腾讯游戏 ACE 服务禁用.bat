@echo off

:: ��Ѷ��Ϸ ACE ������ã��Ż�����

echo "%date% %time%" >>"AntiCheatExpert Service.txt" 2>>&1
net stop "AntiCheatExpert Service" >>"AntiCheatExpert Service.txt" 2>>&1

exit
