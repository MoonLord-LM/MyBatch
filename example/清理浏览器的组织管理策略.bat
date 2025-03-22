@echo off

:: ²Î¿¼
:: https://www.zhihu.com/question/318527439
:: https://www.v2ex.com/t/548318
:: chrome://policy/

reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Policies\Google\Chrome" /f

pause
exit
