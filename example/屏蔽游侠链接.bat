@echo off

set "adv_name=�������ŵ�����Ϸ.url"

del %adv_name%
rd /S /Q %adv_name%
md %adv_name%
attrib +h +s %adv_name%

exit