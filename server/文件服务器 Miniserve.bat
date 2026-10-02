@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，开启本地 Miniserve 文件服务器' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '按提示输入要共享的文件夹路径、用户名和密码，配置保存在 miniserve 文件夹里' -ForegroundColor Green"
powershell -NoProfile -Command "Write-Host '网页访问地址：https://localhost:8443，开启密码和 SSL 加密，支持在网页里上传文件到共享目录的 upload 子文件夹' -ForegroundColor Green"
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

REM 检查 Miniserve 组件
set "miniserve_path="
if exist "!script_dir!miniserve.exe" (
    set "miniserve_path=!script_dir!miniserve.exe"
) else if exist "!cd!\miniserve.exe" (
    set "miniserve_path=!cd!\miniserve.exe"
) else if exist "!script_dir!..\miniserve.exe" (
    set "miniserve_path=!script_dir!..\miniserve.exe"
) else if exist "..\miniserve.exe" (
    set "miniserve_path=..\miniserve.exe"
) else (
    set "miniserve_path=miniserve"
)
"!miniserve_path!" --version >nul 2>&1
if !errorlevel! neq 0 (
    echo 错误：缺少 Miniserve 组件
    echo 请从 https://github.com/svenstaro/miniserve/releases 下载，然后放到脚本所在文件夹
    "explorer.exe" "https://github.com/svenstaro/miniserve/releases"
    echo.
    pause
    endlocal & endlocal & exit /b 1
)



REM 设置配置目录
set "config_dir=!script_dir!miniserve"
set "ssl_key=!config_dir!\ssl-key.pem"
set "ssl_cert=!config_dir!\ssl-cert.pem"
set "auth_file=!config_dir!\auth.txt"
set "path_file=!config_dir!\path.txt"
set "conf_file=!config_dir!\config.conf"
if not exist "!config_dir!" ( md "!config_dir!" )



REM 读取上次保存的配置
set "saved_dir=" & set "saved_user=" & set "saved_hash="
if exist "!path_file!" (
    for /f "usebackq delims=" %%d in ("!path_file!") do set "saved_dir=%%d"
)
if exist "!auth_file!" (
    for /f "usebackq tokens=1,2,3 delims=:" %%a in ("!auth_file!") do (
        set "saved_user=%%a" & set "saved_hash=%%c"
    )
)



REM 输入共享文件夹
:input_folder
if "!saved_dir!"=="" (
    echo 请输入要共享的文件夹路径：
) else (
    echo 请输入要共享的文件夹路径 ^(直接回车沿用：!saved_dir!^)：
)
set /p "input_dir="
if "!input_dir!"=="" (
    if "!saved_dir!"=="" (
        echo 输入不能为空
        echo.
        goto input_folder
    ) else (
        set "input_dir=!saved_dir!"
    )
)

set "input_dir=!input_dir:"=!"
if not exist "!input_dir!\" (
    echo 错误：文件夹不存在
    echo.
    goto input_folder
)

echo.



REM 输入用户名
:input_username
if "!saved_user!"=="" (
    echo 请输入用户名：
) else (
    echo 请输入用户名 ^(直接回车沿用：!saved_user!^)：
)
set /p "input_user="
if "!input_user!"=="" (
    if "!saved_user!"=="" (
        echo 用户名不能为空
        echo.
        goto input_username
    ) else (
        set "input_user=!saved_user!"
    )
)

REM 用户名变更时需要重新输入密码
if not "!input_user!"=="!saved_user!" ( set "saved_hash=" )
echo.



REM 输入密码
:input_password
if "!saved_hash!"=="" (
    echo 请输入密码：
) else (
    echo 请输入密码 ^(直接回车沿用上次密码^)：
)

REM 使用 PowerShell 安全输入密码
set "temp_pw=%temp%\MyBatch_%random%_%random%_%random%_%random%.tmp"
powershell -NoProfile -Command ^
    "$securePassword = Read-Host -AsSecureString;" ^
    "if ($securePassword.Length -eq 0 -and '!saved_hash!' -ne '') {" ^
    "    Write-Output 'password_hash=!saved_hash!';" ^
    "    exit;" ^
    "}" ^
    "if ($securePassword.Length -eq 0) {" ^
    "    Write-Output 'password_hash=';" ^
    "    exit;" ^
    "}" ^
    "$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword);" ^
    "$password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr);" ^
    "[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr);" ^
    "$sha512 = [Security.Cryptography.SHA512]::Create();" ^
    "$hashBytes = $sha512.ComputeHash([Text.Encoding]::UTF8.GetBytes($password));" ^
    "$hash = [BitConverter]::ToString($hashBytes).Replace('-', '').ToLower();" ^
    "Write-Output (\"password_hash=$hash\");" > "!temp_pw!"

for /f "usebackq tokens=1,* delims==" %%a in ("!temp_pw!") do set "password_hash=%%b"
if "!password_hash!"=="" (
    echo 密码不能为空
    echo.
    if exist "!temp_pw!" ( del /f /q "!temp_pw!" )
    goto input_password
)
if exist "!temp_pw!" ( del /f /q "!temp_pw!" )
set "input_hash=!password_hash!"



REM 保存配置
>"!path_file!" echo !input_dir!
>"!auth_file!" echo !input_user!:sha512:!input_hash!
echo 配置已保存到 miniserve 文件夹
echo.



REM 生成 SSL 证书（增强版：使用 SHA-256 和 4096 位密钥）
if not exist "!ssl_cert!" (
    echo 正在生成 SSL 证书...
    "!openssl_path!" req ^
        -x509 ^
        -sha256 ^
        -nodes ^
        -days 3650 ^
        -newkey rsa:4096 ^
        -keyout "!ssl_key!" ^
        -out "!ssl_cert!" ^
        -subj "/CN=Miniserve Of MoonLord/OU=MyBatch/O=MoonLord/C=CN"
    echo SSL 证书生成完成
    echo.
) else (
    echo 复用现有 SSL 证书
    echo.
)



REM 在共享目录内创建 upload 上传文件夹
set "upload_dir=!input_dir!\upload"
if not exist "!upload_dir!" ( md "!upload_dir!" )
echo 上传文件夹：!upload_dir!
echo.



REM 保存完整配置到 conf 文件（含全部启动参数，想看自己打开）
(
    echo # ================= Miniserve 完整配置 =================
    echo # 生成时间：!date! !time!
    echo 共享文件夹：!input_dir!
    echo 上传文件夹：!upload_dir!
    echo 端口：8443，HTTPS
    echo 标题：Miniserve Of MoonLord
    echo 用户名：!input_user!
    echo 认证文件：!auth_file!
    echo SSL 私钥：!ssl_key!
    echo SSL 证书：!ssl_cert!
    echo 网页访问地址：https://localhost:8443/files
    echo.
    echo # 完整启动指令：
    echo "!miniserve_path!" "!input_dir!" --port 8443 --tls-cert "!ssl_cert!" --tls-key "!ssl_key!" --auth "!input_user!:sha512:!input_hash!" --title "Miniserve Of MoonLord" --route-prefix /files --upload-files /upload --rm-files --color-scheme ayu-dark --qrcode
) > "!conf_file!"
echo 完整配置已保存到 config.conf
echo.



REM 显示基础配置信息
powershell -NoProfile -Command "Write-Host '========== 配置信息 ==========' -ForegroundColor Yellow"
echo 共享文件夹：!input_dir!
echo 用户名：!input_user!
echo 网页访问地址：https://localhost:8443/files
echo 完整配置文件：!conf_file!
echo 按 Ctrl+C 停止服务
echo.



REM 尝试打开浏览器访问
timeout /t 2 >nul
echo 正在打开浏览器...
start "" "https://localhost:8443/files"
echo 按任意键启动服务...
pause >nul



REM 启动 Miniserve 服务
echo.
echo 启动 Miniserve 文件服务器...
echo.

"!miniserve_path!" ^
    "!input_dir!" ^
    --port 8443 ^
    --tls-cert "!ssl_cert!" ^
    --tls-key "!ssl_key!" ^
    --auth "!input_user!:sha512:!input_hash!" ^
    --title "Miniserve Of MoonLord" ^
    --route-prefix "/files" ^
    --upload-files /upload ^
    --rm-files ^
    --color-scheme ayu-dark ^
    --qrcode

if !errorlevel! neq 0 (
    echo.
    echo 错误：Miniserve 启动失败
    echo 请检查配置和网络端口
)



echo.
echo Miniserve 服务已停止
pause
endlocal & endlocal & exit /b
