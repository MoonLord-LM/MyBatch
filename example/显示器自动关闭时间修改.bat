@echo off


call :DisplayCurrentACSettings
call :DisplayCurrentDCSettings


echo .
echo �޸��Զ��ر�ʱ��Ϊ 25 ����
powercfg /change monitor-timeout-ac 25
powercfg /change monitor-timeout-dc 25
echo .


call :DisplayCurrentACSettings
call :DisplayCurrentDCSettings


pause
exit


:DisplayCurrentACSettings
    :: powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | findstr "������Դ"
    for /f "tokens=2" %%a in ('powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE ^| findstr "������Դ"') do set MonitorTimeoutACHex=%%a
    set /A MonitorTimeoutAC=%MonitorTimeoutACHex%
    echo AC ������Դ����ǰ���Զ��ر�ʱ��Ϊ %MonitorTimeoutAC% ��
goto :eof

:DisplayCurrentDCSettings
    :: powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | findstr "ֱ����Դ"
    for /f "tokens=2" %%a in ('powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE ^| findstr "ֱ����Դ"') do set MonitorTimeoutDCHex=%%a
    set /A MonitorTimeoutDC=%MonitorTimeoutDCHex%
    echo DC ֱ����Դ����ǰ���Զ��ر�ʱ��Ϊ %MonitorTimeoutDC% ��
goto :eof
