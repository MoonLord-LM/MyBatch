@echo off
chcp 65001 >nul



REM 全局代理
REM git config --global --unset http.proxy
REM git config --global --unset https.proxy
git config --global http.proxy http://127.0.0.1:10809
git config --global https.proxy http://127.0.0.1:10809

REM 查看配置
git config --global -l

pause
exit
