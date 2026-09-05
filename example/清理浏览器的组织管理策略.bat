@echo off
chcp 65001 >nul



REM 参考
REM https://www.zhihu.com/question/318527439
REM https://www.v2ex.com/t/548318
REM chrome://policy/

reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Policies\Google\Chrome" /f



pause
exit
