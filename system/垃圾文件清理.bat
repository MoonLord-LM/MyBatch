@echo off
chcp 65001 >nul
setlocal disabledelayedexpansion
set "script=%~0" & set "script_path=%~f0" & set "script_dir=%~dp0" & set "script_name=%~n0" & set "script_ext=%~x0" & set "script_name_ext=%~nx0"
setlocal enabledelayedexpansion
powershell -NoProfile -Command "Write-Host '[ !script_name_ext! ]' -ForegroundColor Cyan" && echo.



powershell -NoProfile -Command "Write-Host '双击运行，执行垃圾文件的清理' -ForegroundColor Green"
echo.



if /i "!cd!"=="!SystemRoot!\System32" (
    echo 检测到使用右键的“以管理员权限运行”，切换到脚本所在文件夹 & echo.
    cd /d "!script_dir!"
)



:: 龙之谷 DragonNest
set "regValue="
for /f "tokens=2,*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SHENGQUGAMES\DN" /v "Loader"') do (
    set "regValue=%%b"
)
if not "!regValue!"=="" (
    for %%f in ("!regValue!") do set "cleanDir=%%~dpF"
    echo 开始清理：!cleanDir!
    del /q "!cleanDir!\*.dmp" 2>nul
    del /q "!cleanDir!\Log\*.log" 2>nul
    del /q "!cleanDir!\TempRes\*.tmp" 2>nul
    echo 清理完成
) else (
    echo 未在注册表中找到龙之谷的安装路径，跳过
)
echo.

:: 原神 Genshin Impact
set "regValue="
for /f "tokens=2,*" %%a in ('reg query "HKEY_CURRENT_USER\Software\miHoYo\HYP\1_1\hk4e_cn" /v "GameInstallPath"') do (
    set "regValue=%%b"
)
if not "!regValue!"=="" (
    for %%f in ("!regValue!") do set "cleanDir=%%~dpF"
    echo 开始清理：!cleanDir!
    del /q "!cleanDir!\Genshin Impact Game\YuanShen_Data\webCaches\*" 2>nul
    echo 清理完成
) else (
    echo 未在注册表中找到原神的安装路径，跳过
)



echo.
pause
endlocal & endlocal & exit /b
