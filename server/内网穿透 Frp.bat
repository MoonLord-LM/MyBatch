@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，通过 Frp 服务器实现内网穿透' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '需要先自建 Frp 服务器，然后保存参数到 frpc.toml 配置文件里' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 Frp Client 组件
set "frpc_path="
if exist "!script_dir!frpc.exe" (
    set "frpc_path=!script_dir!frpc.exe"
) else if exist "!cd!\frpc.exe" (
    set "frpc_path=!cd!\frpc.exe"
) else if exist "!script_dir!..\frpc.exe" (
    set "frpc_path=!script_dir!..\frpc.exe"
) else if exist "..\frpc.exe" (
    set "frpc_path=..\frpc.exe"
) else (
    set "frpc_path=frpc"
)
"!frpc_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Frp Client 组件
    echo 请从 https://github.com/fatedier/frp/releases 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://github.com/fatedier/frp/releases"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "config_path=!script_dir!frpc.toml"
if not exist "!config_path!" (
    echo 错误：缺少配置文件 frpc.toml & REM
    echo 需要先自建 Frp 服务器，并保存参数到配置文件里，可配置多个隧道 & REM
    echo.
    echo 内容格式如下： & REM
    echo serverAddr = "服务器地址" & REM
    echo serverPort = 服务器连接端口 & REM
    echo auth.method = "token" & REM
    echo auth.token = "服务器连接 token" & REM
    echo [[proxies]] & REM
    echo name = "隧道名称" & REM
    echo type = "隧道传输协议，通常为 http https tcp 等" & REM
    echo localIP = "127.0.0.1" & REM
    echo localPort = 本地监听端口 & REM
    echo remotePort = 服务器映射端口 & REM
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



echo 配置文件：!config_path!
echo.

"!frpc_path!" verify -c "!config_path!"
if !errorlevel! neq 0 (
    echo 错误：配置文件 frpc.toml 格式有误
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

"!frpc_path!" -c "!config_path!"



echo.
pause
endlocal & endlocal & exit /b
