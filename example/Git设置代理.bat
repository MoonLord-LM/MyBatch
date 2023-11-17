@echo off

:: 全局代理
:: git config --global --unset http.proxy
:: git config --global --unset https.proxy
git config --global http.proxy http://127.0.0.1:10809
git config --global https.proxy http://127.0.0.1:10809

:: 查看配置
git config --global -l

pause
exit
