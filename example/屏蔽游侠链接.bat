@echo off

set "adv_name=游侠热门单机游戏.url"

del %adv_name%
rd /S /Q %adv_name%
md %adv_name%
attrib +h +s %adv_name%

exit