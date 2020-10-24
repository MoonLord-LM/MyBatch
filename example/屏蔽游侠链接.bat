@echo off

echo 通过建立同名的隐藏文件夹，来阻止破解版游戏自动创建游侠的链接文件
set adv_name=游侠热门单机游戏.url

del /F /S /Q %adv_name%
rmdir /S /Q %adv_name%
mkdir %adv_name%
attrib +h +s %adv_name%

exit