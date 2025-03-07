@echo off


call :DisplayCurrentACSettings
call :DisplayCurrentDCSettings


echo .
echo 修改自动关闭时间为 25 分钟
powercfg /change monitor-timeout-ac 25
powercfg /change monitor-timeout-dc 25
echo .


call :DisplayCurrentACSettings
call :DisplayCurrentDCSettings


pause
exit


:DisplayCurrentACSettings
    :: powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | findstr "交流电源"
    for /f "tokens=2" %%a in ('powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE ^| findstr "交流电源"') do set MonitorTimeoutACHex=%%a
    set /A MonitorTimeoutAC=%MonitorTimeoutACHex%
    echo AC 交流电源，当前的自动关闭时间为 %MonitorTimeoutAC% 秒
goto :eof

:DisplayCurrentDCSettings
    :: powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | findstr "直流电源"
    for /f "tokens=2" %%a in ('powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE ^| findstr "直流电源"') do set MonitorTimeoutDCHex=%%a
    set /A MonitorTimeoutDC=%MonitorTimeoutDCHex%
    echo DC 直流电源，当前的自动关闭时间为 %MonitorTimeoutDC% 秒
goto :eof
