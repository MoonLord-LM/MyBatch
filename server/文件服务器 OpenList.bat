@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，开启本地 OpenList 文件服务器' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '数据存储目录：OpenListData' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '网页访问地址：https://localhost:15244' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)

REM 检查 OpenSSL-Win64 组件
if exist "!script_dir!openssl.exe" (
    set "openssl_path=!script_dir!openssl.exe"
) else if exist "!cd!\openssl.exe" (
    set "openssl_path=!cd!\openssl.exe"
) else if exist "!script_dir!..\openssl.exe" (
    set "openssl_path=!script_dir!..\openssl.exe"
) else if exist "..\openssl.exe" (
    set "openssl_path=..\openssl.exe"
) else if exist "!ProgramFiles!\OpenSSL-Win64\bin\openssl.exe" (
    set "openssl_path=!ProgramFiles!\OpenSSL-Win64\bin\openssl.exe"
) else if exist "!ProgramFiles!\Git\mingw64\bin\openssl.exe" (
    set "openssl_path=!ProgramFiles!\Git\mingw64\bin\openssl.exe"
) else (
    set "openssl_path=openssl"
)
"!openssl_path!" -version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 OpenSSL-Win64 组件
    echo 请从 https://slproweb.com/products/Win32OpenSSL.html 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://slproweb.com/products/Win32OpenSSL.html"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)

REM 检查 OpenList 组件
set "openlist_path="
if exist "!script_dir!openlist.exe" (
    set "openlist_path=!script_dir!openlist.exe"
) else if exist "!cd!\openlist.exe" (
    set "openlist_path=!cd!\openlist.exe"
) else if exist "!script_dir!..\openlist.exe" (
    set "openlist_path=!script_dir!..\openlist.exe"
) else if exist "..\openlist.exe" (
    set "openlist_path=..\openlist.exe"
)
"!openlist_path!" version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 OpenList 组件
    echo 请从 https://github.com/OpenListTeam/OpenList/releases 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://github.com/OpenListTeam/OpenList/releases"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



set "ssl_subject_name=OpenList"
set "ssl_key=OpenListData\ssl-key.pem"
set "ssl_cert=OpenListData\ssl-cert.pem"

"!openssl_path!" req ^
    -newkey rsa:4096 -nodes -keyout "!ssl_key!" ^
    -x509 -days 365000 -out "!ssl_cert!" ^
    -subj "/CN=!ssl_subject_name!"
echo.

explorer "https://localhost:15244/"
powershell -NoProfile -Command ^
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
    "$env:OPENLIST_HTTP_PORT='-1';" ^
    "$env:OPENLIST_HTTPS_PORT='15244';" ^
    "$env:OPENLIST_KEY_FILE='!ssl_key!';" ^
    "$env:OPENLIST_CERT_FILE='!ssl_cert!';" ^
    "& $env:openlist_path server --data 'OpenListData'"



echo.
pause
endlocal & endlocal & exit /b
