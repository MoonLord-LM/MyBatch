@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，通过 CloudFlare Tunnels 实现内网穿透' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '需要先在 CloudFlare Tunnels 官网创建隧道，并保存参数到 cloudflared.json 配置文件里' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 CloudFlared 组件
if exist "!script_dir!cloudflared.exe" (
    set "cloudflared_path=!script_dir!cloudflared.exe"
) else if exist "!cd!\cloudflared.exe" (
    set "cloudflared_path=!cd!\cloudflared.exe"
) else if exist "!script_dir!..\cloudflared.exe" (
    set "cloudflared_path=!script_dir!..\cloudflared.exe"
) else if exist "..\cloudflared.exe" (
    set "cloudflared_path=..\cloudflared.exe"
) else if exist "C:\Program Files (x86)\cloudflared\cloudflared.exe" (
    set "cloudflared_path=C:\Program Files (x86)\cloudflared\cloudflared.exe"
) else (
    set "cloudflared_path=cloudflared"
)
"!cloudflared_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 CloudFlared 组件
    echo 请从 https://github.com/cloudflare/cloudflared/releases 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://github.com/cloudflare/cloudflared/releases"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "config_path=!script_dir!cloudflared.json"
if not exist "!config_path!" (
    echo 错误：缺少配置文件 cloudflared.json & REM
    echo 请从 CloudFlare Tunnels 官网创建隧道，并保存参数到配置文件里，可配置多个隧道 & REM
    echo.
    echo 内容格式如下： & REM
    echo { & REM
    echo     "隧道外部域名": { & REM
    echo         "token": "隧道 token", & REM
    echo         "protocol": "隧道传输协议，通常为 http 或 https", & REM
    echo         "local_port": "隧道内网监听端口" & REM
    echo     }, & REM
    echo     "xxxxxx1": { & REM
    echo         "token": "xxxxxxxxxxxxxxxxxx1", & REM
    echo         "protocol": "http", & REM
    echo         "local_port": "80" & REM
    echo     }, & REM
    echo     "xxxxxx2": { & REM
    echo         "token": "xxxxxxxxxxxxxxxxxx2", & REM
    echo         "protocol": "https", & REM
    echo         "local_port": "443" & REM
    echo     } & REM
    echo } & REM
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "tmp_file=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp" & type nul > "!tmp_file!"
set "tunnel_count=0"

echo 配置文件：!config_path!
echo 可用域名：
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$cfg = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($env:config_path, [Text.Encoding]::UTF8));" ^
    "foreach ($item in $cfg.PSObject.Properties) {" ^
    "    if ($item.Value.local_port -and $item.Value.token) {" ^
    "        Write-Output $item.Name;" ^
    "    }" ^
    "}" ^
    > "!tmp_file!"
for /f "usebackq delims=" %%h in ("!tmp_file!") do (
    set /a "tunnel_count+=1"
    echo    %%h
)
if exist "!tmp_file!" ( del /f /q "!tmp_file!" )
echo.

if !tunnel_count! equ 0 (
    echo 错误：配置文件中没有可用的隧道配置
    echo.
    pause
    endlocal & endlocal & exit /b 1
)
echo 隧道数量：!tunnel_count!
echo.

:input_host
if "!input_host!"=="" (
    echo 请输入目标域名
    set /p "input_host="
    if !errorlevel! neq 0 (
        echo 无输入，退出脚本
        echo.
        endlocal & endlocal & exit /b 1
    )
    echo.
)
if "!input_host!"=="" (
    echo 输入不能为空，请重新输入
    echo.
    goto input_host
)

powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$cfg = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($env:config_path, [Text.Encoding]::UTF8));" ^
    "foreach ($item in $cfg.PSObject.Properties) {" ^
    "    if ($item.Name -eq $env:input_host) {" ^
    "        Write-Output ('target_host=' + $item.Name);" ^
    "        Write-Output ('target_port=' + $item.Value.local_port);" ^
    "        Write-Output ('target_protocol=' + $item.Value.protocol);" ^
    "        Write-Output ('target_token=' + $item.Value.token);" ^
    "        break;" ^
    "    }" ^
    "}" ^
    > "!tmp_file!"
for /f "usebackq tokens=1,* delims==" %%a in ("!tmp_file!") do (
    set "%%a=%%b"
)
if exist "!tmp_file!" ( del /f /q "!tmp_file!" )

if "!target_token!"=="" (
    echo 错误：不支持该域名 !input_host!，请重新输入
    echo.
    set "input_host="
    goto input_host
)

echo 外部域名：!target_host!
echo 隧道协议：!target_protocol!
echo 本地网址：!target_protocol!://localhost:!target_port!
echo 公网网址：http://!target_host! https://!target_host!
echo.

"!cloudflared_path!" tunnel --logfile "cloudflared.log" run --token "!target_token!"
echo.
taskkill /f /im cloudflared.exe



echo.
pause
endlocal & endlocal & exit /b
